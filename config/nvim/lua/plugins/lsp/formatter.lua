local formatters = {
    javascript      = { "prettierd" },
    javascriptreact = { "prettierd" },
    typescript      = { "prettierd" },
    typescriptreact = { "prettierd" },
    astro           = { "prettierd" },
    json            = { "prettierd" },
    jsonc           = { "prettierd" },
    html            = { "prettierd" },
    yaml            = { "prettierd" },
    css             = { "prettierd", "stylelint" },
    sh              = { "shfmt" },
    go              = { "goimports", "gofmt" },
    lua             = { "stylua" },
    python          = { "isort", "black" },
    csharp          = { "csharpier" }, -- or { "dotnet_format" }
}

return {
    {
        "stevearc/conform.nvim",
        opts = {
            format_on_save = {
                timeout_ms = 2000,
                lsp_fallback = true,
            },
            notify_on_error = true,
            formatters_by_ft = formatters,
        },
    },
}
