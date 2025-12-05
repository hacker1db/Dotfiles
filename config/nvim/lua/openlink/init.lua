local M = {}

local defaults = {
    open_cmd = (vim.fn.has("mac") == 1 and "open" or "xdg-open"),
    filetypes = nil,
    notify = true,
    prefer_obsidian = true,
}

M.opts = {}

local function in_range(col, s, e)
    return col >= s and col <= e
end

local function notify(msg, level)
    if not M.opts.notify then return end
    local ok, snacks = pcall(require, "snacks")
    if ok and snacks and snacks.notify then
        snacks.notify(msg, level or vim.log.levels.INFO)
    else
        vim.notify(msg, level or vim.log.levels.INFO)
    end
end

local function open_external(url)
    if not url or url == "" then return end
    local cmd = { M.opts.open_cmd, url }
    if vim.system then
        vim.system(cmd, { detach = true })
    else
        vim.fn.jobstart(cmd)
    end
    notify("Opened: " .. url)
end

local function stat(path)
    local uv = vim.uv or vim.loop
    return uv.fs_stat(path)
end

local function extract_markdown_link(line, col)
    local i = 1
    while true do
        local s, e = line:find("%[[^%]]-%]%([^%)]-%)", i)
        if not s then break end
        if in_range(col, s, e) then
            local url = line:sub(s, e):match("%[[^%]]-%]%((.-)%)")
            return url
        end
        i = e + 1
    end
end

local function extract_inline_url(line, col)
    local pat = "https?://[%w%-%._~:/%?#%[%]@!$&'()*+,;=]+"
    local i = 1
    while true do
        local s, e = line:find(pat, i)
        if not s then break end
        if in_range(col, s, e) then return line:sub(s, e) end
        i = e + 1
    end
end

local function extract_wiki_link(line, col)
    local i = 1
    while true do
        local s, e, inner = line:find("()%[%[([^%]]-)%]%]()", i)
        if not s then break end
        if in_range(col, s, e - 1) then return inner end
        i = e + 1
    end
end

local function resolve_file(path)
    if not path then return nil end
    if path:match("^[a-z]+://") then return nil end
    if path:sub(1, 1) == "~" then path = vim.fn.expand(path) end
    if stat(path) then return path end
    local abs = vim.fn.fnamemodify(path, ":p")
    if stat(abs) then return abs end
    return nil
end

function M.open()
    if M.opts.filetypes and not vim.tbl_contains(M.opts.filetypes, vim.bo.filetype) then return end
    local pos = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line()
    local col = pos[2] + 1
    local target = extract_markdown_link(line, col)
    if not target then target = extract_inline_url(line, col) end
    if not target then target = extract_wiki_link(line, col) end
    if not target then
        local cfile = vim.fn.expand("<cfile>")
        if cfile ~= "" then target = cfile end
    end
    if not target then return notify("No link under cursor", vim.log.levels.WARN) end
    local file = resolve_file(target)
    if file then
        vim.cmd.edit(vim.fn.fnameescape(file))
        notify("Opened file: " .. file)
        return
    end
    if M.opts.prefer_obsidian and vim.bo.filetype == "markdown" and not target:match("^[a-z]+://") then
        local ok, obs = pcall(require, "obsidian")
        if ok and obs and obs.open then
            obs.open(target)
            notify("Obsidian note: " .. target)
            return
        end
    end
    open_external(target)
end

function M.setup(opts)
    M.opts = vim.tbl_extend("force", defaults, opts or {})
    vim.keymap.set("n", "gx", M.open, { desc = "Open link" })
end

return M
