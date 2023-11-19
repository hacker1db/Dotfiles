return {
  "williamboman/mason.nvim",
"jay-babu/mason-null-ls.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason-lspconfig.nvim", 
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "jose-elias-alvarez/null-ls.nvim"
  },

config = function()
    local mason = require("mason")
    local mason_lspconfig = require("mason-lspconfig")
    local mason_null_ls = require("mason-null-ls")
-- enable mason
mason.setup()

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

mason_null_ls.setup({
    -- list of formatters & linters for mason to install
    ensure_installed = {
        "prettier", -- ts/js formatter
        "stylua", -- lua formatter
        "eslint_d", -- ts/js linter
    },
    -- auto-install configured formatters & linters (with null-ls)
    automatic_installation = true,
        
            })
    end,
}

