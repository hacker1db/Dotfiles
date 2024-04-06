return {
    "williamboman/mason.nvim",
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
    },
    config = function()
        -- import mason
        local mason = require("mason")

        -- import mason-lspconfig
        local mason_lspconfig = require("mason-lspconfig")

        -- enable mason and configure icons
        mason.setup({
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        })

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
                "bashls",
                "mdx_analyzer",
                "tflint",
                "marksman",
            },
        })
    end,
}
