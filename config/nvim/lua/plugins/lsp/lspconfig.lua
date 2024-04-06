--
return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        { "hrsh7th/cmp-nvim-lsp" },
        { "antosha417/nvim-lsp-file-operations", config = true },
        { "folke/neodev.nvim", opts = {} },
    },

    config = function()
        local nvim_lsp = require("lspconfig")

        -- import mason_lspconfig plugin
        local mason_lspconfig = require("mason-lspconfig")

        -- import cmp-nvim-lsp plugin
        local cmp_nvim_lsp = require("cmp_nvim_lsp")
        local keymap = vim.keymap -- for conciseness

        -- vim.api.nvim_create_autocmd("LspAttach", {
        --     group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        --     callback = function(ev)
        --         -- Buffer local mappings.
        --         -- See `:help vim.lsp.*` for documentation on any of the below functions
        --         local opts = { buffer = ev.buf, silent = true } -- buffer local mappings
        --         --
        --         -- set keybinds -- TODO: Add description and possibly move to a separate file for better organization
        --         keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references
        --         keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- got to declaration
        --         keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- see definition and make edits in window
        --         keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- go to implementation
        --         keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- go to implementation
        --         keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions
        --         -- keymap.set({ "n", f("v") }, "<leader>ca", vim.lsp.buf.code_action, opts)         -- see available code actions, in visual mode will apply to selection
        --         keymap.set("n", "<leader>rn", "<cmd>IncRename", opts) -- smart rename
        --         keymap.set("n", "<leader>a", "<cmd>Telescope builtin.diagnostics bufnr=0", opts) -- show  diagnostics for file
        --         keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line
        --         keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer
        --         keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer
        --         keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor
        --         keymap.set("n", "<leader>o", "<cmd>LSoutlineToggle<CR>", opts) -- see outline on right hand side
        --         keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts) -- show signature help
        --
        --         -- typescript specific keymaps (e.g. rename file and update imports)
        --         keymap.set("n", "<leader>rf", ":TypescriptRenameFile<CR>") -- rename file and update imports
        --         keymap.set("n", "<leader>oi", ":TypescriptOrganizeImports<CR>") -- organize imports (not in youtube nvim video)
        --         keymap.set("n", "<leader>ru", ":TypescriptRemoveUnused<CR>") -- remove unused variables (not in youtube nvim video)
        -- other stuff --
        --
        -- require("tailwindcss-colors")

        -- nvim_lsp["tailwindcss"].setup({
        --     -- other settings --
        --     on_attach = on_attach,
        -- })

        -- Set up completion using nvim_cmp with LSP source
        local capabilities = cmp_nvim_lsp.default_capabilities()

        nvim_lsp.flow.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })

        nvim_lsp.tsserver.setup({
            on_attach = on_attach,
            filetypes = {
                "typescript",
                "typescriptreact",
                "typescript.tsx",
                "javascript",
                "javascriptreact",
                "javascript.jsx",
            },
            capabilities = capabilities,
        })

        -- icon
        vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
            underline = true,
            -- This sets the spacing and the prefix, obviously.
            virtual_text = {
                spacing = 4,
                prefix = "",
            },
        })

        -- configure css server
        nvim_lsp.cssls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
        })

        -- configure tailwindcss server
        nvim_lsp.tailwindcss.setup({
            capabilities = capabilities,
            on_attach = on_attach,
        })
        -- configure lua server (with special settings)
        nvim_lsp.lua_ls.setup({
            filetypes = { "lua" },
            capabilities = capabilities,
            on_attach = on_attach,
            settings = { -- custom settings for lua
                Lua = {
                    -- make the language server recognize "vim" global
                    diagnostics = {
                        globals = { "vim" },
                    },
                    workspace = {
                        -- make language server aware of runtime files
                        library = {
                            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                            [vim.fn.stdpath("config") .. "/lua"] = true,
                        },
                    },
                },
            },
        })

        nvim_lsp.gopls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            cmd = { "gopls" },
            filetypes = { "go", "gomod", "go.mod", "gowork", "gotmpl" },
            root_dir = nvim_lsp.util.root_pattern("go.mod", ".git", "go.work"),
            settings = {
                gopls = {
                    completeUnimported = true,
                    usePlaceholders = true,
                    analyses = {
                        unusedparams = true,
                    },
                    staticcheck = true,
                },
            },
        })
        nvim_lsp.csharp_ls.setup({})
        nvim_lsp.golangci_lint_ls.setup({})
        nvim_lsp.jedi_language_server.setup({})
        nvim_lsp.anakin_language_server.setup({})
        nvim_lsp.terraform_lsp.setup({
            cmd = { "terraform-lsp" },
            filetypes = { "terraform", "tf" },
            root_dir = nvim_lsp.util.root_pattern(".git", ".terraform", "terraform.tf"),
            on_attach = on_attach,
            capabilities = capabilities,
        })
        nvim_lsp.powershell_es.setup({

            cmd = { "pwsh", "-NoLogo", "-NoProfile", "-Command" },
        })
        nvim_lsp.csharp_ls.setup({})
        nvim_lsp.pylsp.setup({})
        nvim_lsp.pyright.setup({})
        nvim_lsp.dockerls.setup({})
        nvim_lsp.html.setup({})
        nvim_lsp.astro.setup({
            cmd = { "astro", "lsp" },
            on_attach = on_attach,
            filetypes = { "astro" },
            root_dir = nvim_lsp.util.root_pattern(".git", "astro.toml"),
        })

        nvim_lsp.azure_pipelines_ls.setup({
            cmd = { "azure-pipelines-language-server", "--stdio" },
            filetypes = { "azure-pipelines", "azure-pipelines.yml", "pipelines" },
            settings = {
                yaml = {
                    schemas = {
                        ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = {
                            "/azure-pipeline*.y*l",
                            "/*.azure*",
                            "Azure-Pipelines/**/*.y*l",
                            "Pipelines/*.y*l",
                        },
                    },
                },
            },
        })
    end,
    -- })
    -- end,
}
