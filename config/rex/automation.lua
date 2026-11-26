local terminal = "com.superlogical.terminal"
local home = os.getenv("HOME") or ""
local state_dir = home .. "/.local/share/rex"
local mute_file = state_dir .. "/mute"
local focus_on_bell = os.getenv("REX_BELL_FOCUS") ~= "0"
local exec_path = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

local sounds = {
    claude = "/System/Library/Sounds/Glass.aiff",
    codex = "/System/Library/Sounds/Hero.aiff",
    copilot = "/System/Library/Sounds/Ping.aiff",
    bell = "/System/Library/Sounds/Tink.aiff",
    fail = "/System/Library/Sounds/Basso.aiff",
}

local function run(argv, opts)
    opts = opts or {}
    local r = rex.exec(argv, { cwd = opts.cwd, stdin = opts.stdin, timeout = opts.timeout or 5, env = { PATH = exec_path } })
    if not r or not r.ok then return nil end
    return r.stdout or ""
end

local function muted()
    return run({ "test", "-e", mute_file }) ~= nil
end

local function chime(name)
    if muted() then return end
    rex.exec.start({ "afplay", sounds[name] or sounds.bell }, { detach = true, stdout = false, stderr = false })
end

local function notify(title, text)
    if muted() then return end
    run({ "osascript", "-e", "display notification " .. string.format("%q", text) .. " with title " .. string.format("%q", title) })
end

local function proc(id)
    return rex.block.call(terminal, "process", { block_id = id })
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

local function program(p)
    local f = p and p.foreground
    if not f then return nil end
    return ((f.argv0 or f.name or ""):gsub("^.*/", ""):gsub("^%-", ""))
end

local function screen(id)
    local r = rex.block.call(terminal, "format", { block_id = id, format = "text", trim = true, unwrap = true })
    return r and r.content or ""
end

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

local function basename(p)
    return (tostring(p):gsub("/+$", ""):match("[^/]+$")) or p
end

local function git_label(dir)
    local root = run({ "git", "rev-parse", "--show-toplevel" }, { cwd = dir })
    if not root then return basename(dir) end
    root = root:gsub("%s+$", "")
    local branch = (run({ "git", "branch", "--show-current" }, { cwd = root }) or ""):gsub("%s+$", "")
    return basename(root) .. (branch ~= "" and (":" .. branch) or "")
end

local ours = {}
local agents = {}
local default_labels = { [""] = true, shell = true }

local function relabel(session_id, b, label)
    if ours[b.block_id] == label then return end
    local cur = b.label or ""
    local generated = default_labels[cur] or cur:match("^%a+ · .+ · .+$") or cur:match("^[%w%._%-]+:[%w%._/%-]+$")
    if not generated and ours[b.block_id] ~= cur then return end
    if #label > 120 then label = label:sub(1, 120) end
    if rex.session.set_block_label{ session_id = session_id, block_id = b.block_id, label = label } then
        ours[b.block_id] = label
    end
end

local function since(t)
    local m = math.floor((os.time() - t) / 60)
    if m < 1 then return "" end
    if m < 60 then return " " .. m .. "m" end
    return " " .. math.floor(m / 60) .. "h"
end

local function sweep()
    local s = rex.call("session.list", {})
    local alive = {}
    for _, x in ipairs(s and s.sessions or {}) do
        local bl = rex.call("session.list_blocks", { session_id = x.session_id })
        for _, b in ipairs(bl and bl.blocks or {}) do
            if b.block_id and b.creator_name == terminal and b.placement ~= "detached" then
                alive[b.block_id] = true
                local p = proc(b.block_id)
                local cwd = p and p.foreground and p.foreground.cwd or home
                local agent = agent_of(p)
                if agent then
                    local st = agent_state(screen(b.block_id))
                    local prev = agents[b.block_id]
                    if not prev or prev.state ~= st then
                        if prev and prev.state == "working" and st ~= "working" then
                            chime(agent)
                            notify(agent .. " " .. st, git_label(cwd))
                        end
                        agents[b.block_id] = { state = st, at = os.time() }
                    end
                    local a = agents[b.block_id]
                    relabel(x.session_id, b, agent .. " · " .. a.state .. (a.state == "working" and "" or since(a.at)) .. " · " .. basename(cwd))
                else
                    agents[b.block_id] = nil
                    if program(p) ~= "tmux" then relabel(x.session_id, b, git_label(cwd)) end
                end
            end
        end
    end
    for id in pairs(ours) do if not alive[id] then ours[id] = nil end end
    for id in pairs(agents) do if not alive[id] then agents[id] = nil end end
end

rex.on("terminal.bell", function(ctx, ev)
    local agent = agent_of(proc(ctx.block_id))
    chime(agent or "bell")
    if focus_on_bell and agent then
        rex.session.focus_block{ session_id = ctx.session_id, block_id = ctx.block_id }
    end
end)

rex.on("terminal.child_exited", function(ctx, ev)
    if ev.exit_code and ev.exit_code ~= 0 then
        chime("fail")
        notify("Pane exited with " .. tostring(ev.exit_code), tostring(ctx.block_id))
    end
end)

rex.on("terminal.pwd_changed", function(ctx, ev)
    sweep()
end)

sweep()
rex.every(20, function(ctx)
    local ok, err = pcall(sweep)
    if not ok then rex.log("warn", "automation sweep: " .. tostring(err)) end
end)
