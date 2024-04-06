local formatters = {
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    astro = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    html = { "prettier" },
    yaml = { "prettier" },
    css = { "stylelint", "prettier" },
    sh = { "shellcheck", "shfmt" },
    lua = { "stylua" },
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
