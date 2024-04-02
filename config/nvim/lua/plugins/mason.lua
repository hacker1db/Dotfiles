return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    {

        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "williamboman/mason.nvim",
        },
        config = function()
            local mason_lspconfig = require("mason-lspconfig")
            mason_lspconfig.setup({
                -- list of servers for mason to install
                ensure_installed = {
                    "tsserver",
                    "html",
                    "cssls",
                    "tailwindcss",
                    "lua_ls",
                    "omnisharp",
                    "dockerls",
                    "gopls",
                    "golangci_lint_ls",
                    "marksman",
                    "powershell_es",
                    "jedi_language_server",
                    "sqlls",
                    "yamlls",
                    "terraformls",
                    "omnisharp",
                    "azure_pipelines_ls",
                    "bashls",
                    "tsserver",
                    "tailwindcss",
                    "svelte",
                    "spectral",
                    "jqls",
                },
                -- auto-install configured servers (with lspconfig)
                automatic_installation = true, -- not the same as ensure_installed
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
        },
        config = function()
            local lspconfig = require("lspconfig")
            local keymap = vim.keymap -- for conciseness
            lspconfig.lua_ls.setup({})
            -- keymap.set("n", "K", vim.lsp.buf.hover, {})                    -- show documentation for what is under cursor
            keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {}) -- see available code actions
        end,
    },
}
