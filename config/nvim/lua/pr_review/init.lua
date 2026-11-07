local tier = require("pr_review.tier")

local M = {}

local FIELDS = "number,title,repository,url,author,updatedAt,isDraft,body"
local SECTIONS = {
  { id = "review", title = "Review", flags = { "--review-requested", "@me" }, query = {} },
  { id = "mine", title = "Mine", flags = { "--author", "@me" }, query = {} },
  { id = "involved", title = "Involved", flags = { "--involves", "@me" }, query = { "--", "-author:@me", "-review-requested:@me" } },
}
local SEVERITIES = { "critical", "high", "medium", "low", "info" }
local SEVERITY_HL = { critical = "DiagnosticError", high = "DiagnosticError", medium = "DiagnosticWarn", low = "DiagnosticInfo", info = "DiagnosticHint" }
local PERSONAL = { "hacker1db", "zerobitconsult" }
local AGENTS = {
  { id = "codex", label = "Codex", personal = true, skill = "$pr-review", argv = function(p) return { "codex", p } end },
  { id = "claude-personal", label = "Claude · personal", personal = true, skill = "/pr-review", argv = function(p) return { "claude-personal", p } end },
  { id = "copilot", label = "GitHub Copilot", personal = false, skill = "/pr-review", argv = function(p) return { "copilot", "-i", p } end },
  { id = "claude-work", label = "Claude · work", personal = false, skill = "/pr-review", argv = function(p) return { "claude-subscription", p } end },
  { id = "claude-foundry", label = "Claude · Foundry", personal = false, skill = "/pr-review", argv = function(p) return { "claude-foundry", p } end },
}
local TIER_CACHE = vim.fn.stdpath("state") .. "/pr-review-tiers.json"
local REVIEW_ROOT = vim.fn.expand("~/.local/state/herdr-pr-reviews")

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "PR review" })
end

local function decode(text)
  local ok, data = pcall(vim.json.decode, text, { luanil = { object = true, array = true } })
  if ok then return data end
end

local function gh(args, cb)
  vim.system(vim.list_extend({ "gh" }, args), { text = true, timeout = 120000 }, function(r)
    vim.schedule(function()
      if r.code ~= 0 then
        local err = vim.trim(r.stderr or "")
        return cb(nil, err ~= "" and err or ("gh exited " .. r.code))
      end
      cb(r.stdout)
    end)
  end)
end

local function gh_json(args, cb)
  gh(args, function(out, err)
    if not out then return cb(nil, err) end
    local data = decode(out)
    if data == nil then return cb(nil, "Could not parse gh output") end
    cb(data)
  end)
end

local function parse_url(url)
  local owner, repo, number = (url or ""):match("github%.com/([^/]+)/([^/]+)/pull/(%d+)")
  if owner then return { owner = owner, repo = repo, number = number } end
end

local function age(iso)
  local y, mo, d, h, mi, s = (iso or ""):match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
  if not y then return "" end
  local utc_offset = os.time() - os.time(os.date("!*t"))
  local t = os.time({ year = y, month = mo, day = d, hour = h, min = mi, sec = s }) + utc_offset
  local minutes = math.max(0, math.floor((os.time() - t) / 60 + 0.5))
  if minutes < 60 then return minutes .. "m" end
  if minutes < 1440 then return math.floor(minutes / 60 + 0.5) .. "h" end
  return math.floor(minutes / 1440 + 0.5) .. "d"
end

local function read_json(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local text = f:read("*a")
  f:close()
  return decode(text)
end

local function write_json(path, data)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f = io.open(path, "w")
  if not f then return end
  f:write(vim.json.encode(data))
  f:close()
end

local tiers = read_json(TIER_CACHE) or {}

local function classify(prs, on_progress, on_done)
  local todo, seen = {}, {}
  for _, pr in ipairs(prs) do
    if not seen[pr.url] and (tiers[pr.url] or {}).updatedAt ~= pr.updatedAt then
      seen[pr.url] = true
      todo[#todo + 1] = pr
    end
  end
  if #todo == 0 then return on_done and on_done() end
  local next_index, running = 1, 0
  local function pump()
    while running < 4 and next_index <= #todo do
      local pr = todo[next_index]
      next_index = next_index + 1
      running = running + 1
      gh_json({ "pr", "view", pr.url, "--json", "files" }, function(data)
        running = running - 1
        if data then
          local c = tier.classify_pr(data.files)
          tiers[pr.url] = { updatedAt = pr.updatedAt, tier = c.tier, reason = c.reason }
          if on_progress then on_progress() end
        end
        if running == 0 and next_index > #todo then
          write_json(TIER_CACHE, tiers)
          if on_done then on_done() end
        else
          pump()
        end
      end)
    end
  end
  pump()
end

function M.review_dir(url)
  local pr = parse_url(url)
  if pr then return ("%s/%s/%s/%s"):format(REVIEW_ROOT, pr.owner, pr.repo, pr.number) end
end

function M.resolve_url(arg, cb)
  if arg and arg ~= "" then
    if arg:match("^%d+$") then
      return gh({ "pr", "view", arg, "--json", "url", "-q", ".url" }, function(out, err)
        if out then cb(vim.trim(out)) else notify(err, vim.log.levels.ERROR) end
      end)
    end
    return cb(arg)
  end
  local repo, number = vim.api.nvim_buf_get_name(0):match("^octo://([^/]+/[^/]+)/pull/(%d+)")
  if repo then return cb(("https://github.com/%s/pull/%s"):format(repo, number)) end
  local ok, reviews = pcall(require, "octo.reviews")
  local review = ok and reviews.get_current_review() or nil
  if review and review.pull_request then
    return cb(("https://github.com/%s/pull/%s"):format(review.pull_request.repo, review.pull_request.number))
  end
  gh({ "pr", "view", "--json", "url", "-q", ".url" }, function(out, err)
    if out then cb(vim.trim(out)) else notify(err or "No pull request for this branch", vim.log.levels.WARN) end
  end)
end

local function pr_preview(pr, section)
  local t = tiers[pr.url]
  local lines = {
    ("# #%d %s"):format(pr.number, pr.title),
    "",
    ("- **Repo:** %s"):format(pr.repository and pr.repository.nameWithOwner or ""),
    ("- **Author:** %s"):format(pr.author and pr.author.login or ""),
    ("- **Section:** %s%s"):format(section, pr.isDraft and " · draft" or ""),
    ("- **Updated:** %s ago"):format(age(pr.updatedAt)),
  }
  if t then
    lines[#lines + 1] = ("- **Tier:** %s %s, review %s. %s"):format(tier.ICON[t.tier], t.tier, tier.EFFORT[t.tier], t.reason)
  else
    lines[#lines + 1] = "- **Tier:** classifying…"
  end
  vim.list_extend(lines, { "", "---", "" })
  vim.list_extend(lines, vim.split(pr.body ~= nil and pr.body ~= "" and pr.body:gsub("\r", "") or "_No description_", "\n"))
  return table.concat(lines, "\n")
end

function M.dashboard()
  local state = { data = {}, loading = false }
  local picker

  local function items()
    local out = {}
    for _, s in ipairs(SECTIONS) do
      for _, pr in ipairs(state.data[s.id] or {}) do
        out[#out + 1] = {
          text = table.concat({ s.title, "#" .. pr.number, pr.title, pr.repository and pr.repository.nameWithOwner or "", pr.author and pr.author.login or "" }, " "),
          pr = pr,
          url = pr.url,
          section = s.title,
          preview = { text = pr_preview(pr, s.title), ft = "markdown", loc = false },
        }
      end
    end
    return out
  end

  local function redraw()
    if not picker or picker.closed then return end
    local counts = vim.tbl_map(function(s) return ("%s %d"):format(s.title, #(state.data[s.id] or {})) end, SECTIONS)
    picker.title = ("Pull requests · %s%s"):format(table.concat(counts, " · "), state.loading and " · loading…" or "")
    picker:update_titles()
    picker:find({ refresh = true })
  end

  local function refresh()
    if state.loading then return end
    state.loading = true
    redraw()
    local pending = #SECTIONS
    for _, s in ipairs(SECTIONS) do
      local args = vim.list_extend({ "search", "prs", "--state", "open" }, s.flags)
      vim.list_extend(args, { "--json", FIELDS, "--limit", "30" })
      vim.list_extend(args, s.query)
      gh_json(args, function(list, err)
        if list then
          table.sort(list, function(a, b) return (a.updatedAt or "") > (b.updatedAt or "") end)
          state.data[s.id] = list
        else
          notify(("%s: %s"):format(s.title, err), vim.log.levels.ERROR)
        end
        pending = pending - 1
        if pending == 0 then
          state.loading = false
          local all = {}
          for _, sec in ipairs(SECTIONS) do vim.list_extend(all, state.data[sec.id] or {}) end
          classify(all, redraw, redraw)
        end
        redraw()
      end)
    end
  end

  local function handoff(fn)
    return function(p, item)
      if not item then return end
      p:close()
      vim.schedule(function() fn(item.url) end)
    end
  end

  picker = Snacks.picker({
    title = "Pull requests",
    show_empty = true,
    finder = items,
    preview = "preview",
    matcher = { sort_empty = false },
    format = function(item)
      local pr, t = item.pr, tiers[item.url]
      local dim = pr.isDraft and "SnacksPickerComment" or nil
      return {
        { (t and tier.ICON[t.tier] or "··") .. " ", t and tier.HL[t.tier] or "SnacksPickerComment" },
        { ("%-9s"):format(item.section), "SnacksPickerLabel" },
        { ("#%-6d"):format(pr.number), dim or "Number" },
        { pr.title, dim },
        { ("  %s · %s · %s"):format(pr.repository and pr.repository.nameWithOwner or "", pr.author and pr.author.login or "", age(pr.updatedAt)), "SnacksPickerComment" },
      }
    end,
    confirm = handoff(function(url) vim.cmd("Octo " .. url) end),
    actions = {
      pr_browser = function(_, item) if item then vim.ui.open(item.url) end end,
      pr_tiers = handoff(M.tiers),
      pr_agent = handoff(M.agent),
      pr_findings = handoff(M.findings),
      pr_reload = function() refresh() end,
    },
    win = {
      input = {
        keys = {
          ["<a-o>"] = { "pr_browser", mode = { "n", "i" }, desc = "Open in browser" },
          ["<a-t>"] = { "pr_tiers", mode = { "n", "i" }, desc = "Files by tier" },
          ["<a-a>"] = { "pr_agent", mode = { "n", "i" }, desc = "Review with agent" },
          ["<a-v>"] = { "pr_findings", mode = { "n", "i" }, desc = "Agent findings" },
          ["<a-l>"] = { "pr_reload", mode = { "n", "i" }, desc = "Reload" },
        },
      },
    },
  })
  refresh()
  return picker
end

local function split_diff(text)
  local files, current = {}, nil
  for _, line in ipairs(vim.split(text or "", "\n")) do
    local path = line:match("^diff %-%-git a/.- b/(.*)$")
    if path then
      current = { line }
      files[path] = current
    elseif current then
      current[#current + 1] = line
    end
  end
  return files
end

local function first_line(diff_lines)
  for _, line in ipairs(diff_lines or {}) do
    local n = line:match("^@@ %-%d+,?%d* %+(%d+)")
    if n then return tonumber(n) end
  end
  return 1
end

function M.tiers(arg)
  M.resolve_url(arg, function(url)
    local pending, meta, diffs = 2, nil, {}
    local function done()
      pending = pending - 1
      if pending > 0 then return end
      if not meta then return end
      local c = tier.classify_pr(meta.files)
      if meta.updatedAt then
        tiers[url] = { updatedAt = meta.updatedAt, tier = c.tier, reason = c.reason }
        write_json(TIER_CACHE, tiers)
      end
      local items = {}
      for _, f in ipairs(c.files) do
        local diff = diffs[f.path]
        local exists = vim.fn.filereadable(f.path) == 1
        items[#items + 1] = {
          text = table.concat({ f.tier, f.path, f.reason }, " "),
          f = f,
          file = exists and f.path or nil,
          pos = exists and { first_line(diff), 0 } or nil,
          preview = { text = diff and table.concat(diff, "\n") or ("No textual diff for " .. f.path), ft = "diff", loc = false },
        }
      end
      Snacks.picker({
        title = ("#%d %s %s · %s"):format(meta.number, tier.ICON[c.tier], c.tier, c.reason),
        items = items,
        preview = "preview",
        matcher = { sort_empty = false },
        format = function(item)
          local f = item.f
          return {
            { tier.ICON[f.tier] .. " ", tier.HL[f.tier] },
            { ("%-7s"):format(f.tier), tier.HL[f.tier] },
            { ("+%-4d"):format(f.additions or 0), "DiffAdd" },
            { ("-%-4d "):format(f.deletions or 0), "DiffDelete" },
            { f.path, item.file and "SnacksPickerFile" or "SnacksPickerComment" },
            { "  " .. tier.EFFORT[f.tier] .. " · " .. f.reason, "SnacksPickerComment" },
          }
        end,
        confirm = function(p, item)
          if not item then return end
          if not item.file then return notify(item.f.path .. " is not in this checkout", vim.log.levels.WARN) end
          p:close()
          vim.cmd.edit(vim.fn.fnameescape(item.file))
          pcall(vim.api.nvim_win_set_cursor, 0, { item.pos[1], 0 })
        end,
      })
    end
    gh_json({ "pr", "view", url, "--json", "number,title,updatedAt,files" }, function(data, err)
      if not data then notify(err, vim.log.levels.ERROR) end
      meta = data
      done()
    end)
    gh({ "pr", "diff", url, "--color", "never" }, function(out)
      diffs = split_diff(out)
      done()
    end)
  end)
end

local function review_prompt(agent, url, t)
  return table.concat({
    ("%s %s"):format(agent.skill, url),
    "",
    "Review this pull request with the trunk → branch → leaf priority model:",
    "- trunk: " .. tier.DEFS.trunk,
    "- branch: " .. tier.DEFS.branch,
    "- leaf: " .. tier.DEFS.leaf,
    ("A path-based first pass labels this PR %s (%s); confirm or correct it."):format(t.tier, t.reason),
    "Review trunk files first, then branch, then leaf. Severity ranks findings only within a tier, except that a critical finding is always first.",
    "Do not post anything to GitHub: the reviewer reads your findings in Neovim and submits the review with Octo.",
    "",
    "When you finish, write ./review.json in the current folder, exactly this JSON shape:",
    '{"verdict": "Approve" | "Request changes" | "Comment", "tier": "trunk" | "branch" | "leaf", "tier_reason": "...", "summary": "...",',
    ' "findings": [{"id": "F1", "severity": "critical" | "high" | "medium" | "low" | "info", "tier": "trunk" | "branch" | "leaf",',
    '   "file": "path/in/repo", "line": 123, "title": "...", "detail": "...", "suggestion": "..."}]}',
    "Use the new-file line number of a changed or context line for `line`, or null when a finding has no single line.",
  }, "\n")
end

local function watch_review(url, number)
  local file = M.review_dir(url) .. "/review.json"
  local before = (vim.uv.fs_stat(file) or {}).mtime
  local poll = vim.uv.new_fs_poll()
  poll:start(file, 3000, vim.schedule_wrap(function(_, _, stat)
    if not stat or (before and stat.mtime.sec == before.sec and stat.mtime.nsec == before.nsec) then return end
    poll:stop()
    poll:close()
    local review = read_json(file)
    notify(("Agent review ready for #%s: %s · %d findings · <leader>pv to open"):format(
      number, review and review.verdict or "no verdict", review and review.findings and #review.findings or 0))
  end))
end

function M.agent(arg)
  M.resolve_url(arg, function(url)
    local pr = parse_url(url)
    if not pr then return notify("Not a GitHub pull request: " .. url, vim.log.levels.ERROR) end
    local personal = false
    for _, p in ipairs(PERSONAL) do
      if url:lower():find(p, 1, true) then personal = true end
    end
    local allowed = vim.tbl_filter(function(a) return a.personal == personal end, AGENTS)
    vim.ui.select(allowed, {
      prompt = ("Which agent should review #%s?"):format(pr.number),
      format_item = function(a) return a.label end,
    }, function(agent)
      if not agent then return end
      local function launch(t)
        local dir = M.review_dir(url)
        vim.fn.mkdir(dir, "p")
        Snacks.terminal(agent.argv(review_prompt(agent, url, t)), {
          cwd = dir,
          win = { position = "right", width = 0.45 },
          interactive = true,
        })
        watch_review(url, pr.number)
        notify(("%s is reviewing #%s; nothing is posted to GitHub"):format(agent.label, pr.number))
      end
      local cached = tiers[url]
      if cached then return launch(cached) end
      gh_json({ "pr", "view", url, "--json", "files" }, function(data)
        launch(data and tier.classify_pr(data.files) or { tier = "branch", reason = "unknown" })
      end)
    end)
  end)
end

local function sort_findings(list)
  local function rank(f)
    local sev = vim.fn.index(SEVERITIES, f.severity or "info")
    return (f.severity == "critical" and -100 or 0) + tier.rank(f.tier) * 10 + (sev < 0 and #SEVERITIES or sev)
  end
  table.sort(list, function(a, b) return rank(a) < rank(b) end)
  return list
end

local function finding_body(f)
  local parts = {}
  if f.title then parts[#parts + 1] = ("**%s**"):format(f.title) end
  if f.detail then parts[#parts + 1] = f.detail end
  if f.suggestion then parts[#parts + 1] = "Suggestion: " .. f.suggestion end
  return table.concat(parts, "\n\n")
end

function M.findings(arg)
  M.resolve_url(arg, function(url)
    local dir = M.review_dir(url)
    local review = dir and read_json(dir .. "/review.json")
    if not review then
      return notify("No agent review yet for this PR; start one with <leader>pa", vim.log.levels.WARN)
    end
    local items = {}
    for _, f in ipairs(sort_findings(review.findings or {})) do
      local exists = f.file and vim.fn.filereadable(f.file) == 1
      local where = f.file and (f.file .. (f.line and (":" .. f.line) or "")) or "general"
      items[#items + 1] = {
        text = table.concat({ f.severity or "", f.tier or "", where, f.title or "" }, " "),
        finding = f,
        where = where,
        file = exists and f.file or nil,
        pos = exists and { f.line or 1, 0 } or nil,
        preview = {
          text = table.concat({
            ("# %s %s"):format(f.id or "", f.title or ""),
            "",
            ("- **Severity:** %s"):format(f.severity or "info"),
            ("- **Tier:** %s %s"):format(tier.ICON[f.tier or "branch"] or "", f.tier or "branch"),
            ("- **Location:** `%s`"):format(where),
            "",
            f.detail or "",
            "",
            f.suggestion and ("**Suggestion:** " .. f.suggestion) or "",
          }, "\n"),
          ft = "markdown",
          loc = false,
        },
      }
    end
    local t = review.tier or "branch"
    Snacks.picker({
      title = ("%s %s · %s · %d findings"):format(tier.ICON[t] or "", t, review.verdict or "no verdict", #items),
      items = items,
      preview = "preview",
      matcher = { sort_empty = false },
      format = function(item)
        local f = item.finding
        return {
          { (tier.ICON[f.tier or "branch"] or "  ") .. " " },
          { ("%-9s"):format(f.severity or "info"), SEVERITY_HL[f.severity or "info"] },
          { f.title or "" },
          { "  " .. item.where, "SnacksPickerComment" },
        }
      end,
      confirm = function(p, item)
        if not item then return end
        if not item.file then return notify(item.where .. " is not in this checkout", vim.log.levels.WARN) end
        p:close()
        vim.cmd.edit(vim.fn.fnameescape(item.file))
        pcall(vim.api.nvim_win_set_cursor, 0, { item.pos[1], 0 })
      end,
      actions = {
        finding_yank = function(_, item)
          if not item then return end
          vim.fn.setreg("+", finding_body(item.finding))
          notify("Copied finding as a review comment; paste it into an Octo comment")
        end,
        finding_summary = function()
          vim.fn.setreg("+", review.summary or "")
          notify("Copied review summary")
        end,
      },
      win = {
        input = {
          keys = {
            ["<a-y>"] = { "finding_yank", mode = { "n", "i" }, desc = "Copy as comment" },
            ["<a-s>"] = { "finding_summary", mode = { "n", "i" }, desc = "Copy summary" },
          },
        },
      },
    })
  end)
end

function M.setup()
  local function cmd(name, fn, desc)
    vim.api.nvim_create_user_command(name, function(o) fn(o.args) end, { nargs = "?", desc = desc })
  end
  cmd("PrDashboard", M.dashboard, "Pull requests that need you, with tiers")
  cmd("PrTiers", M.tiers, "Changed files ranked trunk → branch → leaf")
  cmd("PrAgent", M.agent, "Run an agent review in a split")
  cmd("PrFindings", M.findings, "Agent review findings")
end

return M
