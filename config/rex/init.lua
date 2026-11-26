-- Rex config migrated from tmux (~/.config/tmux/tmux.conf) and Ghostty.
--
-- tmux runs inside Rex, and both use ctrl+a as the prefix. So ctrl+a and
-- ctrl+h/j/k/l are Lua key handlers that check the focused terminal's
-- foreground program: when it is tmux (or vim, nvim, fzf for ctrl+h/j/k/l)
-- they return false and the key goes to the terminal; otherwise they run the
-- Rex action tmux has for the same key.
--
-- A key handler may not call rex.client.queue, so it asks the app with
-- client.perform, which needs Remote Control on in Rex.app's settings
-- (install/osx.zsh sets it). If that fails the handler returns false and the
-- terminal gets the key.

local terminal = "com.superlogical.terminal"

-- Name of the focused terminal's foreground program, or nil.
local function foreground()
  local p = rex.block.call(terminal, "process", {})
  return p and p.foreground and p.foreground.name or nil
end

-- Same programs vim-tmux-navigator hands the key to (vim, nvim, view, fzf).
local function wants_nav_keys(name)
  if not name then return false end
  name = name:lower()
  return name:match("^g?%.?view$") ~= nil
      or name:match("^l?n?vim?x?$") ~= nil
      or name:match("^fzf$") ~= nil
      or name:match("^l?n?vim?x?diff$") ~= nil
end

-- Ask the app showing this session to perform one of its actions.
local function perform(ctx, action, args)
  local list = rex.call("client.list", {})
  for _, c in ipairs(list and list.clients or {}) do
    if c.info and c.info.kind == "app" then
      for _, sid in ipairs(c.session_ids or {}) do
        if sid == ctx.session_id then
          return rex.call("client.perform", {
            client_id = c.client_id,
            session_id = ctx.session_id,
            block_id = ctx.block_id,
            action = action,
            args = args,
            origin = "key",
            timeout_ms = 2000,
          }) ~= nil
        end
      end
    end
  end
  return false
end

-- Prefix: ctrl+a enters the one-key "prefix" mode, unless tmux is in front.
rex.mode("prefix", { exclusive = true })
rex.bind("ctrl+a", function(ctx, ev)
  if foreground() == "tmux" then return false end
  return perform(ctx, "client.mode.enter", { name = "prefix", once = true })
end)

-- tmux.conf:23 bind-key a send-prefix
rex.bind("prefix/a", "pane.send_key", { key = "ctrl+a" })
-- tmux.conf:39 bind = select-layout tiled
rex.bind("prefix/=", "pane.balance")
-- tmux.conf:58 bind r source-file ...
rex.bind("prefix/r", "client.config.reload")
-- tmux.conf:60 bind-key x kill-pane
rex.bind("prefix/x", "pane.close")
-- tmux.conf:63 bind N new-window
rex.bind("prefix/shift+n", "client.tab.new")
-- tmux.conf:66-68 splits
rex.bind("prefix/\\", "pane.split", { direction = "right" })
rex.bind("prefix/shift+\\", "pane.split", { direction = "right" })
rex.bind("prefix/-", "pane.split", { direction = "down" })
-- tmux.conf:74-77 pane focus
rex.bind("prefix/h", "pane.focus", { direction = "left" })
rex.bind("prefix/j", "pane.focus", { direction = "down" })
rex.bind("prefix/k", "pane.focus", { direction = "up" })
rex.bind("prefix/l", "pane.focus", { direction = "right" })
-- tmux.conf:83-88 resize / zoom (bind -r)
rex.bind("prefix/shift+h", "pane.resize", { amount = 10, direction = "left" })
rex.bind("prefix/shift+j", "pane.resize", { amount = 10, direction = "down" })
rex.bind("prefix/shift+k", "pane.resize", { amount = 10, direction = "up" })
rex.bind("prefix/shift+l", "pane.resize", { amount = 10, direction = "right" })
rex.bind("prefix/shift+m", "pane.zoom")
-- tmux.conf:118 bind Up new-window ... (swap-pane/select-window not migrated)
rex.bind("prefix/up", "client.tab.new")

-- Repeat mode for tmux `bind -r` bindings: ctrl+a ctrl+r enters, enter/escape leaves.
rex.mode("repeat", { exclusive = true })
rex.bind("prefix/ctrl+r", "client.mode.enter", { name = "repeat" })
rex.bind("repeat/enter", "client.mode.exit")
rex.bind("repeat/escape", "client.mode.exit")
rex.bind("repeat/shift+h", "pane.resize", { amount = 10, direction = "left" })
rex.bind("repeat/shift+j", "pane.resize", { amount = 10, direction = "down" })
rex.bind("repeat/shift+k", "pane.resize", { amount = 10, direction = "up" })
rex.bind("repeat/shift+l", "pane.resize", { amount = 10, direction = "right" })
rex.bind("repeat/shift+m", "pane.zoom")

-- Colors: Rex has no theme setting in init.lua, so this palette action imports
-- the same Eldritch theme Ghostty uses and selects it. Run "Import Eldritch
-- Theme" from the command palette once on a new machine.
rex.action{
  name  = "import_eldritch_theme",
  title = "Import Eldritch Theme",
  description = "Import ~/.config/ghostty/themes/Eldritch (from dotfiles) and select it.",
  category = "Theme",
  run   = function(ctx, args)
    rex.client.queue("client.theme.import", {
      path = os.getenv("HOME") .. "/.config/ghostty/themes/Eldritch",
    })
  end,
}

-- ctrl+h/j/k/l move between panes everywhere (vim-tmux-navigator style).
-- In tmux, vim-tmux-navigator handles the key; in vim/nvim/fzf the program
-- keeps it; otherwise Rex moves focus between its own panes.
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("ctrl+" .. key, function(ctx, ev)
    local program = foreground()
    if program == "tmux" or wants_nav_keys(program) then return false end
    return perform(ctx, "pane.focus", { direction = direction })
  end)
end

local home = os.getenv("HOME") or ""
local shell_flavor = "com.superlogical.terminal.shell"
local exec_path = table.concat({
  "/opt/homebrew/bin",
  "/usr/local/bin",
  home .. "/.local/bin",
  home .. "/Developer/dotfiles/bin",
  home .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS",
  os.getenv("PATH") or "/usr/bin:/bin:/usr/sbin:/sbin",
}, ":")

local function run(argv, opts)
  opts = opts or {}
  local r, err = rex.exec(argv, {
    cwd = opts.cwd,
    stdin = opts.stdin,
    timeout = opts.timeout or 15,
    env = { PATH = exec_path },
  })
  if not r then return nil, tostring(err) end
  if not r.ok then
    local msg = (r.stderr or ""):gsub("%s+$", "")
    return nil, msg ~= "" and msg or ("exit " .. tostring(r.code))
  end
  return r.stdout or ""
end

local function lines(argv, opts)
  local out, err = run(argv, opts)
  if not out then return nil, err end
  local t = {}
  for l in out:gmatch("[^\n]+") do t[#t + 1] = l end
  return t
end

local function fields(s)
  local t = {}
  for f in (s .. "\t"):gmatch("(.-)\t") do t[#t + 1] = f end
  return t
end

local function shq(s)
  return "'" .. (tostring(s):gsub("'", "'\\''")) .. "'"
end

local function basename(p)
  return (tostring(p):gsub("/+$", ""):match("[^/]+$")) or p
end

local function proc(id)
  return rex.block.call(terminal, "process", { block_id = id })
end

local function program(p)
  local f = p and p.foreground
  if not f then return nil end
  return ((f.argv0 or f.name or ""):gsub("^.*/", ""):gsub("^%-", ""))
end

local function agent_of(p)
  local f = p and p.foreground
  if not f then return nil end
  for _, s in ipairs({ f.argv0 or "", f.invoked_path or "", f.path or "", f.name or "" }) do
    local b = s:gsub("^.*/", ""):gsub("^%-", "")
    if b:match("^claude") or s:find("/claude/versions/", 1, true) then return "claude" end
    if b:match("^codex") then return "codex" end
    if b:match("^copilot") or s:find("/copilot", 1, true) then return "copilot" end
  end
  return nil
end

local function cwd_of(id)
  local p = proc(id)
  local f = p and p.foreground
  if f and f.cwd then return f.cwd end
  for _, a in ipairs(p and p.ancestors or {}) do
    if a.cwd then return a.cwd end
  end
  return home
end

local function screen(id)
  local r = rex.block.call(terminal, "format", { block_id = id, format = "text", trim = true, unwrap = true })
  return r and r.content or ""
end

local function last_line(text)
  local t = text:gsub("%s+$", "")
  return t:match("([^\n]*)$") or ""
end

local function terminal_blocks(session_id)
  local r = rex.call("session.list_blocks", { session_id = session_id })
  local out = {}
  for _, b in ipairs(r and r.blocks or {}) do
    if b.block_id and b.creator_name == terminal and b.placement ~= "detached" then
      out[#out + 1] = b
    end
  end
  return out
end

local function all_blocks()
  local out = {}
  local s = rex.call("session.list", {})
  for _, x in ipairs(s and s.sessions or {}) do
    for _, b in ipairs(terminal_blocks(x.session_id)) do
      b.session_id = x.session_id
      b.session_label = x.label
      out[#out + 1] = b
    end
  end
  return out
end

local shells = { zsh = true, bash = true, fish = true, sh = true }

local function type_in(id, text)
  local fg = program(proc(id))
  if fg and not shells[fg] then error("foreground is " .. fg .. ", not a shell", 0) end
  rex.block.call(terminal, "write", { block_id = id, data = text .. "\r" })
end

local function shell_block(dir, input, label)
  local options = { cwd = dir }
  if input then options.initial_input = input .. "\r" end
  return rex.layout.block{ flavor = shell_flavor, options = options, label = label }
end

local function new_tab(label, layout)
  local r, err = rex.session.new_window{ window_label = label, layout = layout, focus = true }
  if not r then error("new tab failed: " .. tostring(err), 0) end
  return r
end

local function new_split(ctx, layout, direction)
  local r, err = rex.session.new_split{
    anchor_id = ctx.block_id,
    direction = direction or "horizontal",
    side = "after",
    layout = layout,
    focus = true,
  }
  if not r then error("split failed: " .. tostring(err), 0) end
  return r
end

local function float(layout, bounds)
  local r, err = rex.session.new_layer{ bounds = bounds or { 0.1, 0.08, 0.8, 0.8 }, layout = layout, focus = true }
  if not r then error("float failed: " .. tostring(err), 0) end
  return r
end

local function repo_root(dir)
  local out = run({ "git", "rev-parse", "--show-toplevel" }, { cwd = dir })
  return out and (out:gsub("%s+$", "")) or nil
end

local function need_repo(ctx)
  local dir = cwd_of(ctx.block_id)
  local root = repo_root(dir)
  if not root then error("not a git repository: " .. dir, 0) end
  return root, dir
end

local function pick(spec)
  local r, why = rex.ui.pick(spec)
  if r == nil and why ~= "cancelled" and why ~= "timeout" then
    rex.log("warn", "pick failed: " .. tostring(why))
  end
  return r
end

local function notify(title, text)
  run({ "osascript", "-e", "display notification " .. string.format("%q", text) .. " with title " .. string.format("%q", title) })
end

local function copy(text)
  local _, err = run({ "pbcopy" }, { stdin = text })
  if err then error("copy failed: " .. err, 0) end
end

local tools = {}

local function tool(spec)
  local action = {}
  for k, v in pairs(spec) do
    if k ~= "key" then action[k] = v end
  end
  rex.action(action)
  tools[#tools + 1] = spec
  if spec.key then
    rex.bind("cmd+;>" .. spec.key, function(ctx, ev)
      local h = rex.exec.start({
        "rex", "--timeout", "15m", "do", spec.name,
        "-s", ctx.session_id, "-b", ctx.block_id, "--origin", "key",
      }, { detach = true, stdout = false, stderr = false, env = { PATH = exec_path } })
      return h ~= nil
    end)
  end
end

local function branch_items(root)
  local refs = lines({ "git", "for-each-ref", "--sort=-committerdate",
    "--format=%(refname)\t%(refname:short)\t%(committerdate:relative)\t%(HEAD)",
    "refs/heads", "refs/remotes" }, { cwd = root }) or {}
  local items, seen = {}, {}
  for _, l in ipairs(refs) do
    local f = fields(l)
    local full, name, when, head = f[1], f[2], f[3], f[4]
    local remote = full:match("^refs/remotes/") ~= nil
    local short = remote and name:gsub("^[^/]+/", "") or name
    if not (remote and (short == "HEAD" or name:match("/HEAD$"))) and not seen[short] then
      seen[short] = true
      items[#items + 1] = {
        id = short,
        title = short,
        subtitle = remote and ("remote " .. name) or nil,
        detail = when,
        icon = head == "*" and "star" or "branch",
      }
    end
  end
  return items
end

local function default_base(root)
  local out = run({ "git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD" }, { cwd = root })
  return out and (out:gsub("%s+$", "")) or nil
end

tool{
  name = "git_branch_picker", title = "Git: Switch Branch", category = "Git", key = "b",
  description = "Switch to a local or remote branch, or type a new name to create one.",
  run = function(ctx)
    local root = need_repo(ctx)
    local choice = pick{ title = "Switch branch", placeholder = "Filter, or type a new branch name",
      items = branch_items(root), allow_other = true, confirm = "Switch" }
    if not choice then return end
    if type(choice) == "table" then
      local base = default_base(root)
      type_in(ctx.block_id, "git switch -c " .. shq(choice.text) .. (base and (" " .. shq(base)) or ""))
    else
      type_in(ctx.block_id, "git switch " .. shq(choice))
    end
  end,
}

local function project_items()
  local dirs = lines({ "find", home .. "/Developer", "-mindepth", "1", "-maxdepth", "1", "-type", "d", "-not", "-name", ".*" }) or {}
  table.sort(dirs, function(a, b) return a:lower() < b:lower() end)
  local items = {}
  for _, d in ipairs(dirs) do
    items[#items + 1] = { id = d, title = basename(d), subtitle = (d:gsub("^" .. home:gsub("%p", "%%%0"), "~")), icon = "folder" }
  end
  return items
end

tool{
  name = "project_picker", title = "Open Project", category = "Navigate", key = "p",
  description = "Open a folder from ~/Developer in a new tab.",
  run = function(ctx)
    local dir = pick{ title = "Open project", items = project_items(), confirm = "Open" }
    if dir then new_tab(basename(dir), shell_block(dir)) end
  end,
}

local function worktree_items(root)
  local out = run({ "git", "worktree", "list", "--porcelain" }, { cwd = root }) or ""
  local items, cur = {}, nil
  for l in (out .. "\n"):gmatch("(.-)\n") do
    local path = l:match("^worktree (.+)")
    if path then
      cur = { id = path, title = basename(path), subtitle = (path:gsub("^" .. home:gsub("%p", "%%%0"), "~")), icon = "folder" }
      items[#items + 1] = cur
    elseif cur and l:match("^branch ") then
      cur.title = l:gsub("^branch refs/heads/", "")
      cur.icon = "branch"
    elseif cur and l == "bare" then
      items[#items] = nil
      cur = nil
    elseif cur and l == "detached" then
      cur.detail = "detached"
    end
  end
  return items
end

tool{
  name = "worktree_picker", title = "Git: Open Worktree", category = "Git", key = "w",
  description = "Open one of this repository's worktrees in a new tab.",
  run = function(ctx)
    local root = need_repo(ctx)
    local items = worktree_items(root)
    local dir = pick{ title = "Open worktree", items = items, confirm = "Open" }
    if not dir then return end
    local label = basename(dir)
    for _, it in ipairs(items) do if it.id == dir then label = it.title end end
    new_tab(label, shell_block(dir))
  end,
}

local function pr_items(root)
  local rows = lines({ "gh", "pr", "list", "--limit", "50", "--json", "number,title,headRefName,author,isDraft",
    "--template", "{{range .}}{{.number}}\t{{.title}}\t{{.headRefName}}\t{{.author.login}}\t{{.isDraft}}\n{{end}}" },
    { cwd = root, timeout = 20 }) or {}
  local items = {}
  for _, l in ipairs(rows) do
    local f = fields(l)
    items[#items + 1] = {
      id = f[1],
      title = "#" .. f[1] .. " " .. (f[2] or ""),
      subtitle = (f[3] or "") .. " · " .. (f[4] or ""),
      detail = f[5] == "true" and "draft" or nil,
      icon = "branch",
    }
  end
  return items
end

tool{
  name = "pr_picker", title = "GitHub: Pull Requests", category = "Git", key = "g",
  description = "Pick an open pull request, then check it out, open it, diff it, or watch its checks.",
  run = function(ctx)
    local root = need_repo(ctx)
    local items = pr_items(root)
    if #items == 0 then error("no open pull requests (or gh failed)", 0) end
    local n = pick{ title = "Pull requests", items = items }
    if not n then return end
    local verb = pick{ title = "PR #" .. n, items = {
      { id = "checkout", title = "Check out", icon = "branch" },
      { id = "web", title = "Open in browser", icon = "globe" },
      { id = "diff", title = "Diff in a split", icon = "code" },
      { id = "checks", title = "Watch checks in a split", icon = "clock" },
      { id = "review", title = "Review with an agent", icon = "person" },
    } }
    if verb == "checkout" then
      type_in(ctx.block_id, "gh pr checkout " .. n)
    elseif verb == "web" then
      run({ "gh", "pr", "view", n, "--web" }, { cwd = root })
    elseif verb == "diff" then
      new_split(ctx, shell_block(root, "gh pr diff " .. n))
    elseif verb == "checks" then
      new_split(ctx, shell_block(root, "gh pr checks " .. n .. " --watch"), "vertical")
    elseif verb == "review" then
      new_split(ctx, shell_block(root, "claude-personal " .. shq("Review pull request #" .. n .. " in this repository.")))
    end
  end,
}

local function status_items(root)
  local rows = lines({ "git", "status", "--porcelain=v1", "--untracked-files=all" }, { cwd = root }) or {}
  local items = {}
  for _, l in ipairs(rows) do
    local x, y, path = l:sub(1, 1), l:sub(2, 2), l:sub(4)
    path = path:match("-> (.+)$") or path
    path = path:gsub('^"(.*)"$', "%1")
    items[#items + 1] = {
      id = path,
      title = path,
      detail = x .. y,
      icon = "document",
      selected = x ~= " " and x ~= "?",
    }
  end
  return items
end

tool{
  name = "git_stage_files", title = "Git: Stage Files", category = "Git", key = "s",
  description = "Pick which changed files are staged. Unpicked staged files are unstaged.",
  run = function(ctx)
    local root = need_repo(ctx)
    local items = status_items(root)
    if #items == 0 then error("working tree is clean", 0) end
    local picked = pick{ title = "Stage files", items = items, multiple = true, confirm = "Stage" }
    if not picked then return end
    local want, add, unstage = {}, {}, {}
    for _, id in ipairs(picked) do want[id] = true end
    for _, it in ipairs(items) do
      if want[it.id] and not it.selected then add[#add + 1] = it.id end
      if it.selected and not want[it.id] then unstage[#unstage + 1] = it.id end
    end
    if #add > 0 then
      local argv = { "git", "add", "--" }
      for _, p in ipairs(add) do argv[#argv + 1] = p end
      local _, err = run(argv, { cwd = root })
      if err then error("git add: " .. err, 0) end
    end
    if #unstage > 0 then
      local argv = { "git", "restore", "--staged", "--" }
      for _, p in ipairs(unstage) do argv[#argv + 1] = p end
      local _, err = run(argv, { cwd = root })
      if err then error("git restore: " .. err, 0) end
    end
    return { staged = #add, unstaged = #unstage }
  end,
}

tool{
  name = "dev_layout", title = "Dev Layout", category = "Navigate", key = "d",
  description = "New tab for this repository: nvim on the left, a shell over lazygit on the right.",
  args = { dir = "string?" },
  run = function(ctx, args)
    local dir = args.dir or cwd_of(ctx.block_id)
    local root = repo_root(dir) or dir
    new_tab(basename(root), rex.layout.horizontal(0.62,
      shell_block(root, "nvim"),
      rex.layout.vertical(0.5, shell_block(root), shell_block(root, "lazygit"))))
  end,
}

local agent_commands = {
  { id = "claude-personal", title = "Claude (personal)", icon = "person" },
  { id = "claude-subscription", title = "Claude (work)", icon = "person" },
  { id = "claude-foundry", title = "Claude (Foundry)", icon = "server" },
  { id = "codex", title = "Codex", icon = "code" },
  { id = "copilot", title = "Copilot", icon = "code" },
}

tool{
  name = "agent_launcher", title = "Agents: Launch", category = "Agents", key = "c",
  description = "Start a coding agent in a split beside this pane, with an optional first prompt.",
  run = function(ctx)
    local cmd = pick{ title = "Launch agent", items = agent_commands, confirm = "Launch" }
    if not cmd then return end
    local prompt = rex.ui.input{ title = "First prompt (optional)", placeholder = "Leave empty to start without one", confirm = "Start" }
    if prompt == nil then return end
    local line = cmd
    if prompt:match("%S") then line = line .. " " .. shq(prompt) end
    new_split(ctx, shell_block(cwd_of(ctx.block_id), line, basename(cmd)))
  end,
}

local snippets = {
  { id = "zsh install/agent-profiles.zsh --check", title = "Audit agent profiles", detail = "dotfiles" },
  { id = "luacheck config/nvim", title = "Lint Neovim config", detail = "dotfiles" },
  { id = "time zsh -i -c exit", title = "Measure shell startup", detail = "zsh" },
  { id = "git diff --check", title = "Whitespace check", detail = "git" },
  { id = "rex config check", title = "Check Rex config", detail = "rex" },
  { id = "rex config reload", title = "Reload Rex config", detail = "rex" },
  { id = "plan doctor --json", title = "Plan manager health", detail = "plan" },
  { id = "gh pr status", title = "My PR status", detail = "gh" },
  { id = "wt list", title = "List worktrees", detail = "wt" },
  { id = "brew outdated", title = "Outdated Homebrew packages", detail = "brew" },
}

tool{
  name = "command_snippets", title = "Command Snippets", category = "Tools", key = "y",
  description = "Type a saved command into this shell, or type a one-off.",
  run = function(ctx)
    local items = {}
    for _, s in ipairs(snippets) do
      items[#items + 1] = { id = s.id, title = s.title, subtitle = s.id, detail = s.detail, icon = "terminal" }
    end
    local choice = pick{ title = "Run command", items = items, allow_other = true, confirm = "Type" }
    if not choice then return end
    type_in(ctx.block_id, type(choice) == "table" and choice.text or choice)
  end,
}

local function listener_items()
  local rows = lines({ "lsof", "-nP", "-iTCP", "-sTCP:LISTEN" }) or {}
  local items, seen = {}, {}
  for i, l in ipairs(rows) do
    if i > 1 then
      local cmd, pid = l:match("^(%S+)%s+(%d+)")
      local port = l:match(":(%d+) %(LISTEN%)")
      if cmd and port and not seen[pid .. ":" .. port] then
        seen[pid .. ":" .. port] = true
        items[#items + 1] = { id = pid .. ":" .. port, title = ":" .. port .. " " .. cmd, detail = "pid " .. pid, icon = "server" }
      end
    end
  end
  table.sort(items, function(a, b) return tonumber(a.id:match(":(%d+)")) < tonumber(b.id:match(":(%d+)")) end)
  return items
end

tool{
  name = "port_killer", title = "Kill Listening Port", category = "Tools", key = "o",
  description = "Pick a process listening on a TCP port and stop it.",
  run = function(ctx)
    local items = listener_items()
    if #items == 0 then error("nothing is listening", 0) end
    local id = pick{ title = "Listening ports", items = items }
    if not id then return end
    local pid = id:match("^(%d+)")
    local sig = pick{ title = "Stop pid " .. pid, items = {
      { id = "TERM", title = "kill (TERM)", icon = "clock" },
      { id = "KILL", title = "kill -9 (KILL)", icon = "star" },
    }, confirm = "Kill" }
    if not sig then return end
    local _, err = run({ "kill", "-" .. sig, pid })
    if err then error("kill: " .. err, 0) end
  end,
}

local function host_items()
  local r = rex.call("hosts.list", {})
  local items = {}
  for _, h in ipairs(r and r.hosts or {}) do
    local ep = h.endpoints and h.endpoints[1] or ""
    local target = ep:match("^ssh://(.+)$")
    if target then
      items[#items + 1] = { id = target, title = h.label ~= "" and h.label or target, subtitle = target, icon = "server" }
    end
  end
  return items
end

tool{
  name = "fleet_hosts", title = "Fleet: Open Host", category = "Fleet", key = "f",
  description = "Open a shell on one Rex host in a new tab, or the same command on several hosts at once.",
  run = function(ctx)
    local items = host_items()
    if #items == 0 then error("no ssh hosts in rex hosts", 0) end
    local picked = pick{ title = "Hosts (pick several to fan out)", items = items, multiple = true, confirm = "Open" }
    if not picked or #picked == 0 then return end
    local cmd = ""
    if #picked > 1 then
      cmd = rex.ui.input{ title = "Command for every host (optional)", placeholder = "e.g. uptime" }
      if cmd == nil then return end
    end
    local layout
    for i = #picked, 1, -1 do
      local line = "ssh -t " .. shq(picked[i])
      if cmd:match("%S") then line = line .. " " .. shq(cmd .. "; exec $SHELL -l") end
      local b = shell_block(home, line, basename(picked[i]))
      layout = layout and rex.layout.vertical(1 / (#picked - i + 1), b, layout) or b
    end
    new_tab(#picked == 1 and picked[1]:gsub("^.*@", "") or ("fleet ×" .. #picked), layout)
  end,
}

local function agent_state(text)
  local rows = {}
  for l in text:gmatch("[^\n]+") do rows[#rows + 1] = l end
  local tail = table.concat(rows, "\n", math.max(1, #rows - 15)):lower()
  if tail:find("do you want to", 1, true) or tail:find("❯ 1. yes", 1, true)
    or tail:find("waiting for approval", 1, true) then
    return "needs you"
  end
  if tail:find("esc to interrupt", 1, true) or tail:find("…%s*%(%d")
    or tail:find("tokens%s*%)") then
    return "working"
  end
  return "idle"
end

local function agent_blocks()
  local out = {}
  for _, b in ipairs(all_blocks()) do
    local p = proc(b.block_id)
    local a = agent_of(p)
    if a then
      local text = screen(b.block_id)
      b.agent = a
      b.state = agent_state(text)
      b.tail = last_line(text)
      b.cwd = p and p.foreground and p.foreground.cwd
      out[#out + 1] = b
    end
  end
  local rank = { ["needs you"] = 1, working = 2, idle = 3 }
  table.sort(out, function(x, y) return rank[x.state] < rank[y.state] end)
  return out
end

local function agent_items(list)
  local items = {}
  for _, b in ipairs(list) do
    items[#items + 1] = {
      id = b.session_id .. "|" .. b.block_id,
      title = b.agent .. " · " .. b.state .. " · " .. basename(b.cwd or "?"),
      subtitle = b.tail,
      detail = b.session_label,
      icon = b.state == "needs you" and "star" or (b.state == "working" and "clock" or "terminal"),
    }
  end
  return items
end

local function split_id(id)
  return id:match("^(.-)|(.+)$")
end

tool{
  name = "agent_tower", title = "Agents: Tower", category = "Agents", key = "t",
  description = "Every agent pane in every session, the ones that need you first. Pick one to jump to it.",
  run = function(ctx)
    local items = agent_items(agent_blocks())
    if #items == 0 then error("no agent panes found", 0) end
    local id = pick{ title = "Agents", items = items, confirm = "Jump" }
    if not id then return end
    local sid, bid = split_id(id)
    rex.session.focus_block{ session_id = sid, block_id = bid }
  end,
}

tool{
  name = "agent_broadcast", title = "Agents: Broadcast Prompt", category = "Agents", key = "shift+t",
  description = "Send one prompt to several agent panes.",
  run = function(ctx)
    local items = agent_items(agent_blocks())
    if #items == 0 then error("no agent panes found", 0) end
    local picked = pick{ title = "Send to agents", items = items, multiple = true, confirm = "Next" }
    if not picked or #picked == 0 then return end
    local text = rex.ui.input{ title = "Prompt for " .. #picked .. " agents", confirm = "Send" }
    if not text or not text:match("%S") then return end
    for _, id in ipairs(picked) do
      local _, bid = split_id(id)
      if agent_of(proc(bid)) then
        rex.block.call(terminal, "write", { block_id = bid, data = text })
        rex.block.call(terminal, "write", { block_id = bid, data = "\r" })
      end
    end
    return { sent = #picked }
  end,
}

local ioc_patterns = {
  { kind = "cve", pat = "CVE%-%d%d%d%d%-%d%d%d%d+", icon = "tag" },
  { kind = "url", pat = "https?://[%w%-%._~:/%?#@!%$&%*%+,;=%%]+", icon = "link" },
  { kind = "ip", pat = "%f[%d]%d+%.%d+%.%d+%.%d+%f[%D]", icon = "server" },
  { kind = "jwt", pat = "eyJ[%w_%-]+%.eyJ[%w_%-]+%.[%w_%-]*", icon = "code" },
  { kind = "ghsa", pat = "GHSA%-%w%w%w%w%-%w%w%w%w%-%w%w%w%w", icon = "tag" },
  { kind = "sha256", pat = "%f[%x]%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%f[^%x]", icon = "document" },
}

local function ioc_items(text)
  local items, seen = {}, {}
  for _, p in ipairs(ioc_patterns) do
    for m in text:gmatch(p.pat) do
      m = m:gsub("[%.,;:%)]+$", "")
      if not seen[m] then
        seen[m] = true
        local shown = p.kind == "jwt" and (m:sub(1, 24) .. "…") or m
        items[#items + 1] = { id = p.kind .. "\t" .. m, title = shown, detail = p.kind, icon = p.icon }
      end
    end
  end
  return items
end

local function ioc_verbs(kind)
  local v = {}
  if kind == "cve" or kind == "ghsa" then
    v[#v + 1] = { id = "open", title = "Open advisory", icon = "globe" }
    v[#v + 1] = { id = "writeup", title = "Start a CVE writeup with Claude", icon = "person" }
  elseif kind == "url" then
    v[#v + 1] = { id = "open", title = "Open in browser", icon = "globe" }
    v[#v + 1] = { id = "caido", title = "curl through Caido (127.0.0.1:8080)", icon = "terminal" }
  elseif kind == "ip" then
    v[#v + 1] = { id = "whois", title = "whois in a split", icon = "server" }
  elseif kind == "jwt" then
    v[#v + 1] = { id = "jwt", title = "Decode in a floating pane", icon = "code" }
  end
  v[#v + 1] = { id = "copy", title = "Copy", icon = "document" }
  return v
end

tool{
  name = "ioc_lens", title = "Security: IOC Lens", category = "Security", key = "i",
  description = "Pick a CVE, URL, IP, JWT, GHSA or SHA-256 from this pane and act on it.",
  run = function(ctx)
    local items = ioc_items(screen(ctx.block_id))
    if #items == 0 then error("no indicators on screen", 0) end
    local choice = pick{ title = "Indicators on screen", items = items }
    if not choice then return end
    local kind, v = choice:match("^(.-)\t(.+)$")
    local verb = pick{ title = kind:upper() .. " " .. (kind == "jwt" and "token" or v), items = ioc_verbs(kind) }
    if not verb then return end
    local dir = cwd_of(ctx.block_id)
    if verb == "copy" then
      copy(v)
    elseif verb == "open" then
      local url = v
      if kind == "cve" then url = "https://nvd.nist.gov/vuln/detail/" .. v end
      if kind == "ghsa" then url = "https://github.com/advisories/" .. v end
      run({ "open", url })
    elseif verb == "writeup" then
      new_split(ctx, shell_block(dir, "claude-personal " .. shq("Write a CVE writeup for " .. v .. " using the cve-writeup skill.")))
    elseif verb == "caido" then
      type_in(ctx.block_id, "curl -sSk -x http://127.0.0.1:8080 " .. shq(v))
    elseif verb == "whois" then
      new_split(ctx, shell_block(dir, "whois " .. shq(v) .. " | less"), "vertical")
    elseif verb == "jwt" then
      float(shell_block(dir, "jwt " .. shq(v) .. "; read -k1 '?press a key to close'; exit"), { 0.15, 0.1, 0.7, 0.75 })
    end
  end,
}

local secret_patterns = {
  { name = "AWS access key", pat = "AKIA[0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z]" },
  { name = "GitHub token", pat = "gh[pousr]_[%w][%w][%w][%w][%w][%w][%w][%w][%w][%w][%w][%w][%w][%w][%w][%w][%w][%w][%w][%w]" },
  { name = "GitHub fine-grained token", pat = "github_pat_[%w_]+" },
  { name = "Slack token", pat = "xox[abprs]%-[%w%-]+" },
  { name = "JWT", pat = "eyJ[%w_%-]+%.eyJ[%w_%-]+%." },
  { name = "private key", pat = "BEGIN [%u ]*PRIVATE KEY" },
  { name = "Anthropic key", pat = "sk%-ant%-[%w_%-]+" },
  { name = "OpenAI key", pat = "sk%-proj%-[%w_%-]+" },
  { name = "Azure connection string", pat = "AccountKey=[%w%+/=]+" },
}

tool{
  name = "secret_sweep", title = "Security: Secret Sweep", category = "Security", key = "v",
  description = "Before sharing your screen, find panes that show token-shaped text and clear them.",
  run = function(ctx)
    local items = {}
    for _, b in ipairs(all_blocks()) do
      local text = screen(b.block_id)
      local hits = {}
      for _, p in ipairs(secret_patterns) do
        if text:find(p.pat) then hits[#hits + 1] = p.name end
      end
      if #hits > 0 then
        items[#items + 1] = {
          id = b.session_id .. "|" .. b.block_id,
          title = (b.label or "pane") .. " · " .. (b.session_label or ""),
          subtitle = "shows: " .. table.concat(hits, ", "),
          icon = "tag",
          selected = true,
        }
      end
    end
    if #items == 0 then
      notify("Secret sweep", "No token-shaped text visible in any pane.")
      return { clean = true }
    end
    local picked = pick{ title = "Clear these panes?", items = items, multiple = true, confirm = "Clear" }
    for _, id in ipairs(picked or {}) do
      local _, bid = split_id(id)
      rex.block.call(terminal, "reset", { block_id = bid })
    end
    return { found = #items, cleared = #(picked or {}) }
  end,
}

local evidence_dir = home .. "/.local/share/rex/evidence"

tool{
  name = "evidence_locker", title = "Security: Save Pane as Evidence", category = "Security", key = "shift+e",
  description = "Save this pane's screen as text and HTML with time, host, folder and SHA-256 hashes.",
  run = function(ctx)
    local note = rex.ui.input{ title = "Evidence note", placeholder = "What this shows (optional)", confirm = "Save" }
    if note == nil then return end
    local stamp = os.date("%Y%m%d-%H%M%S")
    local dir = evidence_dir .. "/" .. os.date("%Y-%m-%d")
    local _, err = run({ "mkdir", "-p", dir })
    if err then error("mkdir: " .. err, 0) end
    local base = dir .. "/" .. stamp
    local text = screen(ctx.block_id)
    local html = rex.block.call(terminal, "format", { block_id = ctx.block_id, format = "html" })
    run({ "tee", base .. ".txt" }, { stdin = text })
    run({ "tee", base .. ".html" }, { stdin = html and html.content or "" })
    local sums = run({ "shasum", "-a", "256", base .. ".txt", base .. ".html" }) or ""
    local host = (run({ "hostname", "-s" }) or ""):gsub("%s+$", "")
    local meta = table.concat({
      "time: " .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
      "host: " .. host,
      "cwd: " .. cwd_of(ctx.block_id),
      "program: " .. tostring(program(proc(ctx.block_id))),
      "note: " .. note,
      "sha256:",
      sums,
    }, "\n")
    run({ "tee", base .. ".meta" }, { stdin = meta })
    notify("Evidence saved", base .. ".txt")
    return { path = base }
  end,
}

local capture_note = os.getenv("REX_CAPTURE_NOTE") or (home .. "/.local/share/rex/captures.md")

tool{
  name = "line_capture", title = "Notes: Capture Lines", category = "Notes", key = "u",
  description = "Pick lines from this pane and append them, with a comment, repo and branch, to a notes file.",
  run = function(ctx)
    local items, n = {}, 0
    for l in screen(ctx.block_id):gmatch("[^\n]+") do
      n = n + 1
      if l:match("%S") then items[#items + 1] = { id = n .. "\t" .. l, title = l } end
    end
    if #items == 0 then error("pane is empty", 0) end
    local picked = pick{ title = "Capture lines", items = items, multiple = true, confirm = "Capture" }
    if not picked or #picked == 0 then return end
    local why = rex.ui.input{ title = "Comment", placeholder = "Why this matters (optional)", confirm = "Save" }
    if why == nil then return end
    local body = {}
    for _, id in ipairs(picked) do body[#body + 1] = id:match("\t(.*)$") end
    local dir = cwd_of(ctx.block_id)
    local root = repo_root(dir)
    local branch = root and (run({ "git", "branch", "--show-current" }, { cwd = root }) or ""):gsub("%s+$", "") or ""
    local where = root and (basename(root) .. (branch ~= "" and (":" .. branch) or "")) or dir
    local text = string.format("\n## %s · %s\n%s\n\n```text\n%s\n```\n",
      os.date("%Y-%m-%d %H:%M"), where, why, table.concat(body, "\n"))
    run({ "mkdir", "-p", (capture_note:match("^(.*)/[^/]+$")) })
    local _, err = run({ "tee", "-a", capture_note }, { stdin = text })
    if err then error("capture failed: " .. err, 0) end
    return { file = capture_note, lines = #body }
  end,
}

tool{
  name = "error_jump", title = "Jump to Error Location", category = "Navigate", key = "e",
  description = "Pick a file:line from this pane's output and open nvim there in a split.",
  run = function(ctx)
    local dir = cwd_of(ctx.block_id)
    local items, seen = {}, {}
    for path, ln in screen(ctx.block_id):gmatch("([%w%._~/%-]+%.[%w]+):(%d+)") do
      local full = path:gsub("^~", home)
      if full:sub(1, 1) ~= "/" then full = dir .. "/" .. full end
      local key = full .. ":" .. ln
      if not seen[key] and run({ "test", "-f", full }) then
        seen[key] = true
        items[#items + 1] = { id = key, title = path .. ":" .. ln, icon = "code" }
      end
    end
    if #items == 0 then error("no file:line locations on screen", 0) end
    local key = pick{ title = "Open location", items = items, confirm = "Open" }
    if not key then return end
    local file, ln = key:match("^(.*):(%d+)$")
    new_split(ctx, shell_block(dir, "nvim +" .. ln .. " " .. shq(file) .. "; exit"))
  end,
}

local function plan_items()
  local out = run({ "plan", "list", "--status", "active", "--json" }, { timeout = 20 })
  local ok, data = pcall(rex.json.decode, out or "")
  local items = {}
  for _, p in ipairs(ok and data and data.plans or {}) do
    items[#items + 1] = { id = p.id, title = p.title, subtitle = p.stage, detail = (p.updated or ""):sub(1, 10), icon = "document" }
    items[#items].path = p.path
    items[#items].url = p.url
  end
  return items
end

tool{
  name = "plan_cockpit", title = "Plans: Open Plan", category = "Notes", key = "shift+p",
  description = "Pick an active plan, then open it in the dashboard, read it in nvim, or start an agent on it.",
  run = function(ctx)
    local items = plan_items()
    if #items == 0 then error("no active plans (or plan failed)", 0) end
    local id = pick{ title = "Active plans", items = items }
    if not id then return end
    local plan
    for _, it in ipairs(items) do if it.id == id then plan = it end end
    local verb = pick{ title = plan.title, items = {
      { id = "web", title = "Open in dashboard", icon = "globe" },
      { id = "read", title = "Read in a floating nvim", icon = "document" },
      { id = "agent", title = "Start Claude on this plan", icon = "person" },
      { id = "copy", title = "Copy plan ID", icon = "tag" },
    } }
    if verb == "web" then
      run({ "open", plan.url })
    elseif verb == "read" then
      float(shell_block(home, "nvim -R " .. shq(plan.path) .. "; exit"))
    elseif verb == "agent" then
      new_split(ctx, shell_block(cwd_of(ctx.block_id), "claude-personal " .. shq("Continue plan " .. id .. ": read it with `plan show " .. id .. " --json` and work the next unchecked step.")))
    elseif verb == "copy" then
      copy(id)
    end
  end,
}

local vault = home .. "/notes/SecondBrain"

tool{
  name = "vault_recall", title = "Notes: Search Vault", category = "Notes", key = "n",
  description = "Search the vault and read a hit in a floating read-only nvim.",
  run = function(ctx)
    local q = rex.ui.input{ title = "Search vault", placeholder = "Words or a regex", confirm = "Search" }
    if not q or not q:match("%S") then return end
    local rows = lines({ "rg", "--files-with-matches", "--ignore-case", "--glob", "*.md", "--sortr", "modified", "--", q, vault }, { timeout = 20 }) or {}
    local items = {}
    for i, p in ipairs(rows) do
      if i > 300 then break end
      local rel = p:sub(#vault + 2)
      items[#items + 1] = { id = p, title = basename(rel):gsub("%.md$", ""), subtitle = rel:match("^(.*)/[^/]+$") or "", icon = "document" }
    end
    if #items == 0 then error("no notes match " .. q, 0) end
    local path = pick{ title = #items .. " notes match " .. q, items = items, confirm = "Read" }
    if path then float(shell_block(vault, "nvim -R " .. shq(path) .. " +/" .. shq(q) .. "; exit")) end
  end,
}

tool{
  name = "peek_panes", title = "Peek at Any Pane", category = "Navigate", key = "j",
  description = "Every pane in every session with its last line of output. Pick one to jump to it.",
  run = function(ctx)
    local items = {}
    for _, b in ipairs(all_blocks()) do
      if b.block_id ~= ctx.block_id then
        local p = proc(b.block_id)
        items[#items + 1] = {
          id = b.session_id .. "|" .. b.block_id,
          title = (program(p) or "?") .. " · " .. basename(p and p.foreground and p.foreground.cwd or "?"),
          subtitle = last_line(screen(b.block_id)),
          detail = b.session_label,
          icon = agent_of(p) and "person" or "terminal",
        }
      end
    end
    if #items == 0 then error("no other panes", 0) end
    local id = pick{ title = "Panes", items = items, confirm = "Jump" }
    if not id then return end
    local sid, bid = split_id(id)
    rex.session.focus_block{ session_id = sid, block_id = bid }
  end,
}

tool{
  name = "session_janitor", title = "Close Old Sessions", category = "Navigate",
  description = "Pick sessions to close. Sessions whose panes all sit at an idle shell are preselected.",
  run = function(ctx)
    local s = rex.call("session.list", {})
    local items = {}
    for _, x in ipairs(s and s.sessions or {}) do
      if x.session_id ~= ctx.session_id then
        local bl = terminal_blocks(x.session_id)
        local idle = true
        for _, b in ipairs(bl) do
          if not shells[program(proc(b.block_id)) or ""] then idle = false end
        end
        items[#items + 1] = {
          id = x.session_id,
          title = x.label ~= "" and x.label or x.session_id,
          subtitle = #bl .. " panes" .. (idle and " · all idle" or ""),
          icon = "terminal",
          selected = idle,
        }
      end
    end
    if #items == 0 then error("no other sessions", 0) end
    local picked = pick{ title = "Close sessions", items = items, multiple = true, confirm = "Close" }
    local closed = 0
    for _, sid in ipairs(picked or {}) do
      if run({ "rex", "kill", sid }) then closed = closed + 1 end
    end
    return { closed = closed }
  end,
}

local automation_script = home .. "/.config/rex/automation.lua"

local function automation_pid()
  local out = run({ "pgrep", "-f", "rex.* do " .. automation_script })
  return out and out:match("(%d+)") or nil
end

tool{
  name = "automation_start", title = "Rex: Start Automation", category = "Tools",
  description = "Start automation.lua for every session: pane labels, agent chimes, bell focus, exit alerts.",
  run = function(ctx)
    local pid = automation_pid()
    if pid then return { running = pid } end
    local h = rex.exec.start({ "rex", "do", automation_script, "--all" },
      { detach = true, stdout = false, stderr = false, env = { PATH = exec_path } })
    if not h then error("could not start automation", 0) end
    return { started = h.pid }
  end,
}

tool{
  name = "automation_stop", title = "Rex: Stop Automation", category = "Tools",
  description = "Stop the background automation script.",
  run = function(ctx)
    local pid = automation_pid()
    if not pid then return { running = false } end
    run({ "kill", pid })
    return { stopped = pid }
  end,
}

tool{
  name = "automation_mute", title = "Rex: Toggle Chimes and Notifications", category = "Tools", key = "shift+m",
  description = "Mute or unmute automation sounds and notifications.",
  run = function(ctx)
    local file = home .. "/.local/share/rex/mute"
    if run({ "test", "-e", file }) then
      run({ "rm", "-f", file })
      notify("Rex", "Chimes on")
      return { muted = false }
    end
    run({ "mkdir", "-p", home .. "/.local/share/rex" })
    run({ "touch", file })
    return { muted = true }
  end,
}

tool{
  name = "rex_tools", title = "Rex: Tools", category = "Tools", key = "space",
  description = "List these tools and their keys, and run one.",
  run = function(ctx)
    local items = {}
    for _, t in ipairs(tools) do
      if t.name ~= "rex_tools" then
        items[#items + 1] = { id = t.name, title = t.title, subtitle = t.description,
          detail = t.key and ("⌘; " .. t.key) or nil, icon = "gear" }
      end
    end
    local name = pick{ title = "Rex tools", items = items, confirm = "Run" }
    if name then return rex.invoke(name) end
  end,
}

tool{
  name = "rex_selftest", title = "Rex: Self-Test Tools", category = "Tools",
  description = "Run every picker's data source without prompting and report item counts.",
  run = function(ctx)
    local dir = cwd_of(ctx.block_id)
    local root = repo_root(dir)
    local r = {
      cwd = dir,
      repo = root,
      program = program(proc(ctx.block_id)),
      agent = agent_of(proc(ctx.block_id)),
      screen_bytes = #screen(ctx.block_id),
      projects = #project_items(),
      listeners = #listener_items(),
      hosts = #host_items(),
      plans = #plan_items(),
      blocks = #all_blocks(),
      agents = #agent_blocks(),
      iocs = #ioc_items(screen(ctx.block_id)),
      rex_bin = run({ "which", "rex" }),
    }
    if root then
      r.branches = #branch_items(root)
      r.worktrees = #worktree_items(root)
      r.changed_files = #status_items(root)
      r.prs = #pr_items(root)
    end
    return r
  end,
}

rex.bind("prefix/z", "pane.minimize_floating")
rex.bind("prefix/shift+z", "pane.new_floating")
rex.bind("prefix/m", "client.mode.enter", { name = "move" })
rex.mode("move", { exclusive = true })
rex.bind("move/h", "pane.move.left")
rex.bind("move/j", "pane.move.down")
rex.bind("move/k", "pane.move.up")
rex.bind("move/l", "pane.move.right")
rex.bind("move/f", "pane.float")
rex.bind("move/t", "pane.move_to_new_tab")
rex.bind("move/=", "pane.balance")
rex.bind("move/enter", "client.mode.exit")
rex.bind("move/escape", "client.mode.exit")
