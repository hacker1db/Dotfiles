return {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
        flavour = is_dark and "mocha" or "latte",
        dim_inactive = { enabled = false, shade = "dark", percentage = 0.15 },
        transparent_background = true,
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
            },
            lsp_trouble = false,
            cmp = true,
            gitsigns = true,
            telescope = true,
            markdown = true,
            ts_rainbow = true,
        },
    },

    config = function()
        vim.cmd.colorscheme("catppuccin-mocha")
    end,
}
