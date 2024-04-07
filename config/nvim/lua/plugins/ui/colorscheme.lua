return {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,

    config = function()
        require("catppuccin").setup({
            flavour = "mocha",
            background = {
                light = "latte",
                dark = "mocha",
            },
            transparent_background = true, -- disables setting the background color.
            term_colors = true,
            compile = { enabled = true, path = vim.fn.stdpath("cache") .. "/catppuccin", suffix = "_compiled" },
            styles = {
                comments = { "italic" },
                conditionals = { "italic" },
                loops = {},
                functions = { "bold" },
                keywords = {},
                strings = {},
                variables = {},
                numbers = {},
                booleans = {},
                properties = {},
                types = {},
                operators = {},
            },
            integrations = {
                treesitter = true,
                native_lsp = {
                    enabled = true,
                    virtual_text = {
                        errors = { "italic" },
                        hints = { "italic" },
                        warnings = { "italic" },
                        information = { "italic" },
                    },
                    underlines = {
                        errors = { "underline" },
                        hints = { "underline" },
                        warnings = { "underline" },
                        information = { "underline" },
                    },
                    inlay_hints = {
                        background = true,
                    },
                },
                lsp_trouble = true,
                cmp = true,
                gitsigns = true,
                telescope = true,
                markdown = true,
                ts_rainbow = true,
                harpoon = true,
                nvimtree = true,
                indent_blankline = true,
                mason = true,
                neogit = true,
                noice = true,
                dap = true,
                dap_ui = true,
                which_key = true,
            },
        })
        -- setup must be called before loading
        vim.cmd.colorscheme("catppuccin")
    end,
}
