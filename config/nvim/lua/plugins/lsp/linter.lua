return {

    { -- Linting
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            linters = {
                -- https://github.com/LazyVim/LazyVim/discussions/4094#discussioncomment-10178217
                ["markdownlint-cli2"] = {
                    args = { "--config", os.getenv("HOME") .. "/.dotfiles/.markdownlint.yaml", "--" },
                },
            },
        },
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = {
                markdown = { "markdownlint", "markdownlint-cli2" },
                lua = { "luacheck" },
                python = { "flake8" },
                sh = { "shellcheck" },
                vim = { "vint" },
                yaml = { "yamllint" },
                typescript = { "eslint" },
                javascript = { "eslint" },
                json = { "jsonlint" },
                go = {},
                svelete = { "svelte-check" },
                terraform = { "tflint" },
                dockerfile = { "hadolint" },
                codespell = { "codespell" },
                primisma = { "prisma-lint" },
                ruby = { "rubocop" },
                rust = { "cargo" },
                ansible = { "ansible-lint" },
                zsh = { "shellcheck", "zsh" },
            }

            local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
            vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
                group = lint_augroup,
                callback = function()
                    require("lint").try_lint()
                end,
            })
        end,
    },
}
