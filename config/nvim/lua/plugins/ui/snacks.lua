return {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    opts = {
        notifier = { enabled = true, timeout = 3000, top_down = false },
        indent = { enabled = true, char = "┊" },
        scroll = { enabled = true },
        words = { enabled = true },
        bufdelete = { enabled = true },
        zen = { enabled = true },
        terminal = { enabled = true },
        lazygit = { enabled = true },
        picker = { enabled = true },
        explorer = { enabled = true, layout = { preset = "left", width = 30 } },
        dashboard = {
            enabled = true,
            sections = {
                {
                    section = "header",
                    padding = 1,
                    text = {
                        "                                                     ",
                        "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
                        "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
                        "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
                        "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
                        "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
                        "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
                        "                                                     ",
                    },
                },
                {
                    section = "keys",
                    gap = 1,
                    keys = {
                        { icon = " ", key = "n", desc = "New File", action = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_buf_get_option(buf, "filetype")
        if ft == "snacks_explorer" then pcall(vim.api.nvim_win_close, win, true) end
    end
    vim.cmd("ene")
end },
                        { icon = " ", key = "e", desc = "Explorer", action = function()
    local ok, ex = pcall(require, "snacks.explorer")
    if ok then
        -- if already open it will be closed by helper logic in keymaps via toggle; here just open (will auto layout)
        ex.open()
    end
end },
                        { icon = "󰱼 ", key = "f", desc = "Find Files", action = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_buf_get_option(buf, "filetype")
        if ft == "snacks_explorer" then pcall(vim.api.nvim_win_close, win, true) end
    end
    local ok, p = pcall(require, "snacks.picker"); if ok then p.files() end
end },
                        { icon = " ", key = "s", desc = "Search", action = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_buf_get_option(buf, "filetype")
        if ft == "snacks_explorer" then pcall(vim.api.nvim_win_close, win, true) end
    end
    local ok, p = pcall(require, "snacks.picker"); if ok then p.grep() end
end },
                        { icon = " ", key = "q", desc = "Quit", action = function() vim.cmd("qa") end },
                    },
                },
                { section = "startup" },
            },
        },
        quickfile = { enabled = true },
        image = { enabled = true },
        gitbrowse = { enabled = true },
        statuscolumn = { enabled = true },
    },
    config = function(_, opts)
        local snacks = require("snacks")
        snacks.setup(opts)
        vim.notify = snacks.notifier.notify
    end,
}
