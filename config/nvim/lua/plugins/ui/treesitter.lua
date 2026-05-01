return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        event = { "BufReadPre", "BufNewFile" },
        build = ":TSUpdate",
        config = function(plugin)
            -- Append runtime/ so queries are found without prepending the plugin root,
            -- which would override user queries in ~/.config/nvim (e.g. queries/vim/highlights.scm)
            vim.opt.rtp:append(plugin.dir .. "/runtime")
            require("nvim-treesitter").setup()
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-context",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("treesitter-context").setup({
                enable = true,
                multiwindow = false,
                max_lines = 0,
                min_window_height = 0,
                line_numbers = true,
                multiline_threshold = 20,
                trim_scope = "outer",
                mode = "cursor",
                separator = nil,
                zindex = 20,
                on_attach = nil,
            })
        end,
    },
    {
        "windwp/nvim-ts-autotag",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("nvim-ts-autotag").setup()
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = {
                    enable = true,
                    lookahead = true,
                    keymaps = {
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",
                        ["ac"] = "@class.outer",
                        ["ic"] = "@class.inner",
                    },
                },
                swap = {
                    enable = true,
                    swap_next     = { ["<leader>a"] = "@parameter.inner" },
                    swap_previous = { ["<leader>A"] = "@parameter.inner" },
                },
            })
        end,
    },
    { "JoosepAlviste/nvim-ts-context-commentstring", lazy = true },
}
