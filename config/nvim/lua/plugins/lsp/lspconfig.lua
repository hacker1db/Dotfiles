return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        { "antosha417/nvim-lsp-file-operations", config = true },
        { "folke/neodev.nvim", opts = {} },
    },
    config = function()
        -- import lspconfig plugin
        local lspconfig = require("lspconfig")

        -- import mason_lspconfig plugin
        local mason_lspconfig = require("mason-lspconfig")

        -- import cmp-nvim-lsp plugin
        local cmp_nvim_lsp = require("cmp_nvim_lsp")

        -- used to enable autocompletion (assign to every lsp server config)
        local capabilities = cmp_nvim_lsp.default_capabilities()

        -- Change the Diagnostic symbols in the sign column (gutter)
        -- (not in youtube nvim video)
        local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
        for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
        end

        mason_lspconfig.setup_handlers({
            -- default handler for installed servers
            function(server_name)
                lspconfig[server_name].setup({
                    capabilities = capabilities,
                })
            end,
            ["svelte"] = function()
                -- configure svelte server
                lspconfig["svelte"].setup({
                    capabilities = capabilities,
                    on_attach = function(client, _)
                        vim.api.nvim_create_autocmd("BufWritePost", {
                            pattern = { "*.js", "*.ts" },
                            callback = function(ctx)
                                -- Here use ctx.match instead of ctx.file
                                client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
                            end,
                        })
                    end,
                })
            end,
            ["graphql"] = function()
                -- configure graphql language server
                lspconfig["graphql"].setup({
                    capabilities = capabilities,
                    filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
                })
            end,
            ["emmet_ls"] = function()
                -- configure emmet language server
                lspconfig["emmet_ls"].setup({
                    capabilities = capabilities,
                    filetypes = {
                        "html",
                        "typescriptreact",
                        "javascriptreact",
                        "css",
                        "sass",
                        "scss",
                        "less",
                        "svelte",
                    },
                })
            end,
            ["lua_ls"] = function()
                -- configure lua server (with special settings)
                lspconfig["lua_ls"].setup({
                    capabilities = capabilities,
                    settings = {
                        Lua = {
                            -- make the language server recognize "vim" global
                            diagnostics = {
                                globals = { "vim" },
                            },
                            completion = {
                                callSnippet = "Replace",
                            },
                        },
                    },
                })
            end,
            ["tailwindcss"] = function()
                -- configure lua server (with special settings)
                lspconfig["tailwindcss"].setup({
                    capabilities = capabilities,
                    validate = true,
                    tailwindCSS = {
                        lint = {
                            cssConflict = "warning",
                            invalidApply = "error",
                            invalidConfigPath = "error",
                            invalidScreen = "error",
                            invalidTailwindDirective = "error",
                            invalidVariant = "error",
                            recommendedVariantOrder = "warning",
                        },
                    },
                })
            end,
            ["eslint"] = function()
                lspconfig.eslint.setup({
                    root_dir = require("lspconfig").util.root_pattern(
                        "eslint.config.js",
                        ".eslintrc.js",
                        ".eslintrc.json",
                        ".eslintrc"
                    ),
                    on_attach = function(_, bufnr)
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            buffer = bufnr,
                            command = "EslintFixAll",
                        })
                    end,
                })
            end,
            ["gopls"] = function()
                -- configure gopls server (with special settings)
                lspconfig.gopls.setup({
                    capabilities = capabilities,
                    cmd = { "gopls" },
                    filetypes = { "go", "gomod", "go.mod", "gowork", "gotmpl" },
                    root_dir = lspconfig.util.root_pattern("go.mod", ".git", "go.work"),
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
            end,
            ["azure_pipelines_ls"] = function()
                lspconfig.azure_pipelines_ls.setup({
                    cmd = { "azure-pipelines-language-server", "--stdio" },
                    filetypes = { "azure-pipelines", "azure-pipelines.yml", "pipelines" },
                    root_dir = lspconfig.util.root_pattern(".git", ".azure-pipelines", "azure-pipelines.yml"),
                    settings = {
                        yaml = {
                            schemas = {
                                ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = {
                                    "/azure-pipeline*.y*l",
                                    "/*.azure*",
                                    "Azure-Pipelines/**/*.y*l",
                                    "Pipelines/*.y*l",
                                    "YAML/*.y*l",
                                },
                            },
                        },
                    },
                })
            end,
            ["yamlls"] = function()
                lspconfig.yamlls.setup({
                    capabilities = capabilities,
                    schemas = {
                        ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json"] = "/*.k8s.yaml",
                        kubernetes = {
                            "/*.yaml",
                            "/*.yml",
                            "kustomization.yaml",
                            "kustomization.yml",
                            "kustomization",
                            "manifests/*.yaml",
                        },
                    },
                })
            end,
            ["csharp_ls"] = function()
                lspconfig.csharp_ls.setup({
                    capabilities = capabilities,
                })
            end,
            ["golangci_lint_ls"] = function()
                lspconfig.golangci_lint_ls.setup({
                    capabilities = capabilities,
                })
            end,
            ["jedi_language_server"] = function()
                lspconfig.jedi_language_server.setup({
                    capabilities = capabilities,
                })
            end,
            ["terraformls"] = function()
                lspconfig.terraformls.setup({
                    filetypes = { "terraform", "tf" },
                    root_dir = lspconfig.util.root_pattern(".git", ".terraform", "terraform.tf", "main.tf", "data.tf"),
                    capabilities = capabilities,
                })
                vim.api.nvim_create_autocmd({ "BufWritePre" }, {
                    pattern = { "*.tf", "*.tfvars" },
                    callback = function()
                        vim.lsp.buf.format()
                    end,
                })
            end,
            ["powershell_es"] = function()
                lspconfig.powershell_es.setup({
                    cmd = { "pwsh", "-NoLogo", "-NoProfile", "-Command" },
                    capabilities = capabilities,
                })
            end,
            ["pylsp"] = function()
                lspconfig.pylsp.setup({
                    capabilities = capabilities,
                })
            end,
            ["pyright"] = function()
                lspconfig.pyright.setup({
                    capabilities = capabilities,
                })
            end,
            ["dockerls"] = function()
                lspconfig.dockerls.setup({
                    capabilities = capabilities,
                })
            end,
            ["html"] = function()
                lspconfig.html.setup({
                    capabilities = capabilities,
                })
            end,
            ["astro"] = function()
                lspconfig.astro.setup({
                    cmd = { "astro", "lsp" },
                    filetypes = { "astro" },
                    root_dir = lspconfig.util.root_pattern(".git", "astro.toml"),
                    capabilities = capabilities,
                })
            end,
        })
    end,
}
