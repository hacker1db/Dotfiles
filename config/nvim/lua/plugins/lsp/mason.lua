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
                    "bashls",
                    "mdx_analyzer",
                    "tflint",
                    "marksman",
                },
                -- auto-install configured servers (with lspconfig)
                automatic_installation = true, -- not the same as ensure_installed
            })
        end,
    },
}
