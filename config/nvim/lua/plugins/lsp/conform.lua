local formatters = {
    javascript = { "prettierd" },
    javascriptreact = { "prettierd" },
    typescript = { "prettierd" },
    typescriptreact = { "prettierd" },
    astro = { "prettierd" },
    json = { "prettierd" },
    jsonc = { "prettierd" },
    html = { "prettierd" },
    yaml = { "prettierd" },
    css = { "stylelint", "prettierd" },
    sh = { "shellcheck", "shfmt" },
    go = { "gofmt", "goimports" },
    lua = { "stylua" },
    python = { "isort", "black" },
    csharp = { "omnisharp" },
}

return {
    {
        "stevearc/conform.nvim",
        opts = {
            format_on_save = {
                timeout_ms = 2000,
                lsp_fallback = false,
            },
            formatters_by_ft = formatters,
        },
    },
}
