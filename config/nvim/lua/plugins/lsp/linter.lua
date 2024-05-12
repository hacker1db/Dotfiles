return {

    { -- Linting
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = {
                markdown = { "markdownlint" },
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

            -- Create autocommand which carries out the actual linting
            -- on the specified events.
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
