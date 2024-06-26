return {

    "nvimtools/none-ls.nvim",

    config = function()
        local null_ls = require("null-ls")
        -- for conciseness
        local formatting = null_ls.builtins.formatting -- to setup formatters
        local diagnostics = null_ls.builtins.diagnostics -- to setup linters
        local completion = null_ls.builtins.completion -- to set up completion
        local code_actions = null_ls.builtins.code_actions -- set up code actions
        -- to setup format on save
        local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

        -- configure null_ls
        null_ls.setup({
            -- setup formatters & linters
            sources = {
                completion.spell, -- spell check
                completion.luasnip, -- luasnip
                completion.spell, -- spelling is hard

                formatting.stylua, -- lua formatter
                formatting.prettier, -- js/ts formatter
                formatting.prettierd.with({ -- js/ts linter
                    condition = function(utils)
                        return utils.root_has_file(".eslintrc.js", ".eslintrc.json") -- change file extension if you use something else
                    end,
                }),
                formatting.goimports, -- go formatter
                formatting.gofmt, -- go formatter
                code_actions.gitsigns,
            },
            -- configure format on save
            on_attach = function(current_client, bufnr)
                if current_client.supports_method("textDocument/formatting") then
                    vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        group = augroup,
                        buffer = bufnr,
                        callback = function()
                            vim.lsp.buf.format({
                                filter = function(client)
                                    --  only use null-ls for formatting instead of lsp server
                                    return client.name == "null-ls"
                                end,
                                bufnr = bufnr,
                            })
                        end,
                    })
                end
            end,
        })
    end,
}
