return {

    { -- Linting
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lint = require("lint")
            lint.linters["markdownlint-cli2"].args = {
                "-",
                "--config",
                os.getenv("HOME") .. "/.dotfiles/.markdownlint.yaml",
            }
            lint.linters_by_ft = {
                markdown = { "markdownlint-cli2" },
                lua = { "luacheck" },
                python = { "flake8" },
                sh = { "shellcheck" },
                vim = { "vint" },
                yaml = { "yamllint" },
                typescript = { "eslint" },
                javascript = { "eslint" },
                json = { "jsonlint" },
                go = {},
                -- svelte: diagnostics come from the svelte language server (no nvim-lint adapter)
                terraform = { "tflint" },
                dockerfile = { "hadolint" },
                codespell = { "codespell" },
                prisma = { "prisma-lint" },
                ruby = { "rubocop" },
                rust = { "clippy" },
                ansible = { "ansible_lint" },
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
