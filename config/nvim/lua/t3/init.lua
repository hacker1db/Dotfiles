-- t3: drive T3 Code agent threads from Neovim through the `t3` CLI.
--
-- Every CLI call is async (vim.system); nothing blocks the UI. The CLI command
-- comes from opts.cmd, then $T3_CLI, then "t3". It may be a string with
-- arguments ("node ~/src/t3code/apps/server/src/bin.ts") or a list.
--
-- The last thread used per project is stored in
-- ~/.local/state/t3-cli/last-threads.json, shared with bin/t3m.

local M = {}

local ACTIVE = { preparing = true, queued = true, starting = true, running = true, waiting = true }

M.config = {
  cmd = nil, -- string or list; nil = $T3_CLI or "t3"
  base_dir = nil, -- T3 data dir (exported as T3CODE_HOME); nil = $T3_BASE_DIR, else the CLI default (~/.t3)
  -- Extra `thread start` flags (list or string); nil = $T3_START_ARGS,
  -- e.g. "--provider claudeAgent --model claude-haiku-5-5".
  start_args = nil,
  messages = 20, -- messages shown by :T3Show
  refresh_ms = 3000, -- :T3Show auto-refresh interval while a turn is active (0 = off)
  timeout = 120000, -- ms per CLI call (calls with --wait are not used)
  open_on_start = true, -- open :T3Show after :T3Start
  show_split = "botright vsplit", -- how :T3Show opens its window; "float" for a float
  -- Same path as bin/t3m, which honors $XDG_STATE_HOME.
  state_file = (vim.env.XDG_STATE_HOME or vim.fn.expand("~/.local/state")) .. "/t3-cli/last-threads.json",
}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "T3" })
end

local function decode(text)
  local ok, data = pcall(vim.json.decode, text or "", { luanil = { object = true, array = true } })
  if ok then return data end
end

-- Split a string of words (or copy a list), expanding only a leading ~.
-- vim.fn.expand would also expand %, #, $VAR, and globs.
local function words(value)
  if value == nil or value == "" then return {} end
  local list = type(value) == "table" and vim.deepcopy(value) or vim.split(vim.trim(value), "%s+")
  for i, word in ipairs(list) do
    list[i] = (word:gsub("^~", vim.env.HOME))
  end
  return list
end

-- Resolve the CLI command into an argv prefix.
local function cli()
  local argv = words(M.config.cmd or vim.env.T3_CLI)
  if #argv == 0 then argv = { "t3" } end
  return argv
end

-- T3 data dir, or nil for the CLI default. `--base-dir` only works after the
-- subcommand, so it is passed as T3CODE_HOME, which every CLI version reads.
local function base_dir()
  local dir = M.config.base_dir or vim.env.T3_BASE_DIR
  if dir == nil or dir == "" then return nil end
  return (dir:gsub("^~", vim.env.HOME))
end

-- Run `t3 <args>`; cb(stdout) on success, cb(nil, err) on failure. opts.stdin, opts.cwd.
local function run(args, opts, cb)
  opts = opts or {}
  local argv = vim.list_extend(cli(), args)
  local home = base_dir()
  local ok, err = pcall(vim.system, argv, {
    text = true,
    stdin = opts.stdin,
    cwd = opts.cwd,
    env = home and { T3CODE_HOME = home } or nil,
    timeout = M.config.timeout,
  }, function(r)
    vim.schedule(function()
      if r.code ~= 0 then
        local msg = vim.trim(r.stderr or "")
        if msg == "" then msg = vim.trim(r.stdout or "") end
        return cb(nil, msg ~= "" and msg or ("t3 exited " .. r.code))
      end
      cb(r.stdout or "")
    end)
  end)
  if not ok then
    vim.schedule(function() cb(nil, ("could not run %s: %s"):format(argv[1], err)) end)
  end
end

local function run_json(args, opts, cb)
  run(vim.list_extend(vim.deepcopy(args), { "--json" }), opts, function(out, err)
    if not out then return cb(nil, err) end
    local data = decode(out)
    if data == nil then return cb(nil, "could not parse t3 output: " .. vim.trim(out):sub(1, 200)) end
    cb(data)
  end)
end

-- Report a CLI error, or call fn with the result.
local function guard(fn)
  return function(out, err)
    if out == nil then return notify(err, vim.log.levels.ERROR) end
    fn(out)
  end
end

---------------------------------------------------------------------------
-- last-thread state (shared with bin/t3m)
---------------------------------------------------------------------------

local function read_state()
  local f = io.open(M.config.state_file, "r")
  if not f then return {} end
  local data = decode(f:read("*a"))
  f:close()
  return type(data) == "table" and data or {}
end

local function write_state(state)
  vim.fn.mkdir(vim.fs.dirname(M.config.state_file), "p")
  local tmp = M.config.state_file .. ".tmp"
  local f = io.open(tmp, "w")
  if not f then return end
  f:write(vim.json.encode(state))
  f:close()
  os.rename(tmp, M.config.state_file)
end

local function last_thread(project_id)
  return read_state()[project_id]
end

local function remember(project_id, thread_id)
  if not project_id or not thread_id then return end
  local state = read_state()
  state[project_id] = thread_id
  write_state(state)
end

---------------------------------------------------------------------------
-- project resolution
---------------------------------------------------------------------------

-- Directory the current buffer belongs to: its git root, else its folder, else cwd.
local function context_dir(buf)
  buf = buf or 0
  if vim.b[buf].t3_project_dir then return vim.b[buf].t3_project_dir end
  local name = vim.api.nvim_buf_get_name(buf)
  local start = (name ~= "" and vim.bo[buf].buftype == "") and vim.fs.dirname(name) or vim.fn.getcwd()
  return vim.fs.root(start, ".git") or start
end

local function realpath(p)
  return vim.uv.fs_realpath(p) or vim.fs.normalize(p)
end

local function contains(root, path)
  return path == root or path:sub(1, #root + 1) == root .. "/"
end

-- A project table: { id, title, workspaceRoot, key }. `key` (the real path of
-- the workspace root) indexes the last-thread state, so it is the same whether
-- the project came from `t3 project list` or the path fallback below.
local function as_project(p)
  p.key = realpath(p.workspaceRoot)
  -- Thread ids from another T3 home are meaningless here; keep their state apart.
  local home = base_dir()
  if home then p.key = realpath(home) .. "::" .. p.key end
  return p
end

-- cb(project) for the T3 project whose workspace root holds dir (longest match).
-- CLIs without `project list` (t3 <= 0.1.9), or one that cannot read the
-- running server's database, fall back to the directory itself: thread
-- commands accept any path inside a project.
local function resolve_project(dir, cb)
  run_json({ "project", "list" }, nil, function(projects)
    if type(projects) ~= "table" or not vim.islist(projects) then
      return cb(as_project({ id = dir, title = vim.fs.basename(dir), workspaceRoot = dir, fallback = true }))
    end
    local target = realpath(dir)
    local best
    for _, p in ipairs(projects) do
      if p.deletedAt == nil and p.workspaceRoot then
        local root = realpath(p.workspaceRoot)
        if contains(root, target) and (not best or #root > #best.root) then
          best = { project = p, root = root }
        end
      end
    end
    if best then return cb(as_project(best.project)) end
    vim.ui.select({ "Add " .. dir .. " as a T3 project", "Cancel" }, { prompt = "No T3 project for " .. dir }, function(_, idx)
      if idx ~= 1 then return end
      run({ "project", "add", dir }, nil, guard(function()
        notify("Added project " .. dir)
        resolve_project(dir, cb)
      end))
    end)
  end)
end

---------------------------------------------------------------------------
-- message input
---------------------------------------------------------------------------

-- Open a markdown compose float. <C-s>, :w, or <CR> in normal mode submits; q / <Esc> cancels.
local function compose(title, initial, on_submit)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_name(buf, ("t3-compose://%s/%d"):format(title:gsub("%s+", "-"), buf))
  if initial and initial ~= "" then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(initial, "\n"))
  end
  local width = math.min(100, math.floor(vim.o.columns * 0.7))
  local height = math.min(20, math.floor(vim.o.lines * 0.5))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = (" %s · <C-s> send · q cancel "):format(title),
    title_pos = "center",
  })
  vim.wo[win].wrap = true
  local done = false
  local function submit()
    if done then return end
    done = true
    local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
    vim.bo[buf].modified = false
    vim.cmd.stopinsert() -- <C-s> from insert mode would otherwise leave the next window in insert mode
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    if text == "" then return notify("Empty message; nothing sent", vim.log.levels.WARN) end
    on_submit(text)
  end
  local function cancel()
    done = true
    vim.bo[buf].modified = false
    vim.cmd.stopinsert()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  vim.api.nvim_create_autocmd("BufWriteCmd", { buffer = buf, callback = submit })
  local o = { buffer = buf, nowait = true }
  vim.keymap.set({ "n", "i" }, "<C-s>", submit, o)
  vim.keymap.set("n", "<CR>", submit, o)
  vim.keymap.set("n", "q", cancel, o)
  vim.keymap.set("n", "<Esc>", cancel, o)
  -- A selection block starts with two blank lines; type the instruction above it.
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  vim.cmd.startinsert()
end

-- Selected lines as a fenced block with a file:line header.
local function selection_block(line1, line2)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  local name = vim.api.nvim_buf_get_name(0)
  local rel = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]"
  local where = line1 == line2 and ("%s:%d"):format(rel, line1) or ("%s:%d-%d"):format(rel, line1, line2)
  return ("%s\n```%s\n%s\n```"):format(where, vim.bo.filetype, table.concat(lines, "\n"))
end

-- Read a command's range into cmd.t3_block now, before any async CLI call or
-- picker can change the current buffer.
local function capture(cmd)
  if cmd and cmd.range and cmd.range > 0 and not cmd.t3_block then
    cmd.t3_block = selection_block(cmd.line1, cmd.line2)
  end
  return cmd
end

-- cb(message). Uses args when given; a range becomes a code block below a
-- typed instruction; otherwise opens the compose float.
local function get_message(title, cmd, cb)
  if cmd and cmd.args and cmd.args ~= "" then return cb(cmd.args) end
  local block = cmd and cmd.t3_block
  compose(title, block and ("\n\n" .. block) or nil, cb)
end

---------------------------------------------------------------------------
-- thread pickers
---------------------------------------------------------------------------

local function thread_label(t, last)
  local mark = t.threadId == last and "★ " or "  "
  return ("%s%-11s %s"):format(mark, t.status or "?", t.title or t.threadId)
end

-- cb(thread_item, project) after picking one of the project's threads.
local function pick_thread(project, cb)
  run_json({ "thread", "list", "--project", project.id }, nil, guard(function(threads)
    if #threads == 0 then return notify("No threads in " .. project.title) end
    local last = last_thread(project.key)
    -- Last-used thread first; the rest keep the CLI's newest-first order.
    local ordered = {}
    for _, t in ipairs(threads) do
      if t.threadId == last then table.insert(ordered, 1, t) else ordered[#ordered + 1] = t end
    end
    threads = ordered
    vim.ui.select(threads, {
      prompt = "T3 thread · " .. project.title,
      format_item = function(t) return thread_label(t, last) end,
    }, function(t)
      if t then
        remember(project.key, t.threadId)
        cb(t, project)
      end
    end)
  end))
end

-- cb(thread_id, project): last thread for the buffer's project unless force_pick.
local function with_thread(force_pick, cb)
  resolve_project(context_dir(), function(project)
    local last = not force_pick and last_thread(project.key)
    if last then return cb(last, project) end
    pick_thread(project, function(t) cb(t.threadId, project) end)
  end)
end

---------------------------------------------------------------------------
-- actions
---------------------------------------------------------------------------

function M.start(cmd)
  capture(cmd)
  local dir = context_dir()
  resolve_project(dir, function(project)
    local function launch(extra)
      get_message("T3 start · " .. project.title, cmd, function(msg)
        local args = { "thread", "start" }
        vim.list_extend(args, words(M.config.start_args or vim.env.T3_START_ARGS))
        vim.list_extend(args, extra or {})
        vim.list_extend(args, { project.id, "-" }) -- run_json adds --json; a second one is rejected
        notify("Starting thread in " .. project.title .. "…")
        run_json(args, { stdin = msg }, guard(function(res)
          remember(project.key, res.threadId)
          notify(("Started %s"):format(res.threadId))
          if M.config.open_on_start ~= false then M.show(res.threadId, project) end
        end))
      end)
    end
    if not (cmd and cmd.bang) then return launch() end
    -- :T3Start! asks for a worktree base ref and branch.
    vim.ui.input({ prompt = "Worktree base ref: ", default = "main" }, function(base)
      if not base or base == "" then return end
      vim.ui.input({ prompt = "New branch (empty = auto): " }, function(branch)
        local extra = { "--worktree", base }
        if branch and branch ~= "" then vim.list_extend(extra, { "--branch", branch }) end
        launch(extra)
      end)
    end)
  end)
end

local function deliver(thread_id, project, mode, cmd)
  local verb = mode == "steer" and "steer" or "send"
  get_message(("T3 %s · %s"):format(verb, thread_id), cmd, function(msg)
    -- queue is the CLI default; leaving --mode off keeps older CLIs working.
    local args
    if mode == "steer" then
      args = { "thread", "steer", thread_id, "-" }
    elseif mode == "queue" then
      args = { "thread", "send", thread_id, "-" }
    else
      args = { "thread", "send", "--mode", mode, thread_id, "-" }
    end
    run(args, { stdin = msg }, guard(function(out)
      remember(project and project.key, thread_id)
      notify(vim.trim(out) ~= "" and vim.trim(out) or "Sent.")
      M.refresh_thread(thread_id)
    end))
  end)
end

function M.send(cmd, mode)
  mode = mode or "queue"
  capture(cmd)
  with_thread(cmd and cmd.bang, function(id, project) deliver(id, project, mode, cmd) end)
end

function M.steer(cmd)
  capture(cmd)
  with_thread(cmd and cmd.bang, function(id, project) deliver(id, project, "steer", cmd) end)
end

local function stop_thread(thread_id)
  run({ "thread", "stop", thread_id }, nil, guard(function(out)
    notify(vim.trim(out) ~= "" and vim.trim(out) or "Stopped.")
    M.refresh_thread(thread_id)
  end))
end

function M.stop(cmd)
  with_thread(cmd and cmd.bang, function(id) stop_thread(id) end)
end

---------------------------------------------------------------------------
-- transcript buffer
---------------------------------------------------------------------------

local views = {} -- thread_id -> { buf, timer, project, status }

local function render(view, data)
  local t = data.thread or {}
  view.status = t.status
  local lines = {
    "# " .. (t.title or "?"),
    "",
    ("`%s`  **%s**  %s/%s"):format(t.threadId or "?", t.status or "?", t.providerInstanceId or "?", t.model or "?"),
  }
  if t.worktreePath and t.worktreePath ~= vim.NIL then
    lines[#lines + 1] = ("branch `%s`  %s"):format(t.branch or "(none)", t.worktreePath)
  end
  if (t.pendingRequestCount or 0) > 0 then
    lines[#lines + 1] = ("> ⚠ waiting for %d answer(s) — answer in the T3 app or `t3`"):format(t.pendingRequestCount)
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "<!-- r refresh · a auto-refresh · s send · S steer · x stop · q close -->"
  for _, m in ipairs(data.messages or {}) do
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("## %s"):format(m.role == "user" and "▶ user" or "◀ assistant")
    lines[#lines + 1] = ""
    vim.list_extend(lines, vim.split(m.text or "", "\n"))
  end
  local buf = view.buf
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local old = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if vim.deep_equal(old, lines) then return end
  local wins = vim.fn.win_findbuf(buf)
  -- Keep following the bottom when the cursor was already at the end.
  local follow = {}
  for _, w in ipairs(wins) do follow[w] = vim.api.nvim_win_get_cursor(w)[1] >= #old end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  for _, w in ipairs(wins) do
    if follow[w] then vim.api.nvim_win_set_cursor(w, { #lines, 0 }) end
  end
end

local function fetch(view, thread_id)
  if view.busy then return end
  view.busy = true
  run_json({ "thread", "show", "--messages", tostring(M.config.messages), thread_id }, nil, function(data, err)
    view.busy = false
    if not data then
      if not view.silent then notify(err, vim.log.levels.ERROR) end
      return
    end
    render(view, data)
  end)
end

function M.refresh_thread(thread_id)
  local view = views[thread_id]
  if view and vim.api.nvim_buf_is_valid(view.buf) then fetch(view, thread_id) end
end

local function stop_timer(view)
  if view.timer then
    view.timer:stop()
    view.timer:close()
    view.timer = nil
  end
end

local function start_timer(view, thread_id)
  if view.timer or (M.config.refresh_ms or 0) <= 0 then return end
  view.timer = vim.uv.new_timer()
  view.timer:start(M.config.refresh_ms, M.config.refresh_ms, vim.schedule_wrap(function()
    if not vim.api.nvim_buf_is_valid(view.buf) then return stop_timer(view) end
    -- Only poll while visible and either a turn is active or auto is forced on.
    if #vim.fn.win_findbuf(view.buf) == 0 then return end
    if view.auto == "on" or (view.auto ~= "off" and (view.status == nil or ACTIVE[view.status])) then
      view.silent = true
      fetch(view, thread_id)
    end
  end))
end

local function open_window(buf)
  local existing = vim.fn.win_findbuf(buf)[1]
  if existing then return vim.api.nvim_set_current_win(existing) end
  if M.config.show_split == "float" then
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    vim.api.nvim_open_win(buf, true, {
      relative = "editor", width = width, height = height, style = "minimal", border = "rounded",
      row = math.floor((vim.o.lines - height) / 2), col = math.floor((vim.o.columns - width) / 2),
    })
  else
    vim.cmd(M.config.show_split)
    vim.api.nvim_win_set_buf(0, buf)
  end
  vim.wo.wrap = true
  vim.wo.linebreak = true
  vim.wo.conceallevel = 2
end

function M.show(thread_id, project)
  local view = views[thread_id]
  if not view or not vim.api.nvim_buf_is_valid(view.buf) then
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modifiable = false
    pcall(vim.api.nvim_buf_set_name, buf, "t3://" .. thread_id)
    view = { buf = buf, project = project, auto = "active" }
    views[thread_id] = view
    if project then vim.b[buf].t3_project_dir = project.workspaceRoot end
    local o = { buffer = buf, nowait = true }
    local function map(lhs, fn, desc) vim.keymap.set("n", lhs, fn, vim.tbl_extend("force", o, { desc = desc })) end
    map("r", function() view.silent = false; fetch(view, thread_id) end, "T3 refresh")
    map("a", function()
      view.auto = ({ active = "on", on = "off", off = "active" })[view.auto]
      notify("Auto-refresh: " .. ({ active = "while running", on = "always", off = "off" })[view.auto])
    end, "T3 cycle auto-refresh")
    map("s", function() deliver(thread_id, view.project, "queue") end, "T3 send")
    map("S", function() deliver(thread_id, view.project, "steer") end, "T3 steer")
    map("x", function() stop_thread(thread_id) end, "T3 stop")
    map("q", "<cmd>close<cr>", "Close")
    vim.api.nvim_create_autocmd("BufWipeout", {
      buffer = buf,
      callback = function() stop_timer(view); views[thread_id] = nil end,
    })
    start_timer(view, thread_id)
  end
  if project then remember(project.key, thread_id) end
  open_window(view.buf)
  view.silent = false
  fetch(view, thread_id)
end

function M.show_cmd(cmd)
  if cmd.args ~= "" then return M.show(cmd.args) end
  with_thread(cmd.bang, function(id, project) M.show(id, project) end)
end

---------------------------------------------------------------------------
-- threads browser
---------------------------------------------------------------------------

local function thread_actions(t, project)
  local actions = {
    { "Show transcript", function() M.show(t.threadId, project) end },
    { "Send (queue)", function() deliver(t.threadId, project, "queue") end },
    { "Steer running turn", function() deliver(t.threadId, project, "steer") end },
    { "Send (restart turn)", function() deliver(t.threadId, project, "restart") end },
    { "Stop", function() stop_thread(t.threadId) end },
    { "Copy thread id", function()
      vim.fn.setreg("+", t.threadId)
      notify("Copied " .. t.threadId)
    end },
  }
  if t.link then
    actions[#actions + 1] = { "Open in browser", function() vim.ui.open(t.link) end }
  end
  vim.ui.select(actions, {
    prompt = t.title or t.threadId,
    format_item = function(a) return a[1] end,
  }, function(a) if a then a[2]() end end)
end

function M.threads(cmd)
  local function browse(project) pick_thread(project, thread_actions) end
  if not (cmd and cmd.bang) then return resolve_project(context_dir(), browse) end
  -- :T3Threads! picks the project first.
  run_json({ "project", "list" }, nil, guard(function(projects)
    projects = vim.tbl_filter(function(p) return p.deletedAt == nil and p.archivedAt == nil end, projects)
    for _, p in ipairs(projects) do as_project(p) end
    vim.ui.select(projects, {
      prompt = "T3 project",
      format_item = function(p) return ("%s  %s"):format(p.title, vim.fn.fnamemodify(p.workspaceRoot, ":~")) end,
    }, function(p) if p then browse(p) end end)
  end))
end

---------------------------------------------------------------------------
-- providers
---------------------------------------------------------------------------

local function provider_label(row)
  local source = row.projectOverride and ("project " .. row.projectOverride) or "inherits"
  return ("%s %-32s %-14s %s"):format(row.allowed and "✓" or "✗", row.id, source, row.name or row.driver or "")
end

local function providers_menu(project)
  run_json({ "project", "providers", project.id }, nil, guard(function(rows)
    vim.ui.select(rows, {
      prompt = "T3 providers · " .. project.title .. " (pick one to change)",
      format_item = provider_label,
    }, function(row)
      if not row then return end
      local choices = {
        { "Allow in this project", "--allow" },
        { "Block in this project", "--deny" },
        { "Inherit global setting", "--inherit" },
        { "Allow ONLY this instance (block the rest)", "--only" },
      }
      vim.ui.select(choices, { prompt = row.id, format_item = function(c) return c[1] end }, function(c)
        if not c then return end
        run({ "project", "providers", project.id, c[2], row.id }, nil, guard(function()
          notify(("%s %s"):format(c[1], row.id))
          providers_menu(project)
        end))
      end)
    end)
  end))
end

function M.providers(cmd)
  resolve_project(context_dir(), function(project)
    if cmd and cmd.args ~= "" then
      -- :T3Providers --allow codex --deny claudeAgent ...
      local args = vim.list_extend({ "project", "providers", project.id }, cmd.fargs)
      return run(args, nil, guard(function(out) notify(vim.trim(out)) end))
    end
    providers_menu(project)
  end)
end

---------------------------------------------------------------------------
-- setup
---------------------------------------------------------------------------

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  local cmd = vim.api.nvim_create_user_command
  cmd("T3Start", M.start, { nargs = "*", range = true, bang = true, desc = "T3: start a thread (! = in a new worktree)" })
  cmd("T3Send", function(c) M.send(c, "queue") end, { nargs = "*", range = true, bang = true, desc = "T3: send to last thread (! = pick)" })
  cmd("T3Steer", M.steer, { nargs = "*", range = true, bang = true, desc = "T3: steer last thread (! = pick)" })
  cmd("T3Stop", M.stop, { bang = true, desc = "T3: stop last thread (! = pick)" })
  cmd("T3Show", M.show_cmd, { nargs = "?", bang = true, desc = "T3: show transcript of last thread (! = pick)" })
  cmd("T3Threads", M.threads, { bang = true, desc = "T3: browse project threads (! = pick project)" })
  cmd("T3Providers", M.providers, {
    nargs = "*",
    desc = "T3: view/set project provider instances",
    complete = function() return { "--allow", "--deny", "--inherit", "--only" } end,
  })
end

return M
