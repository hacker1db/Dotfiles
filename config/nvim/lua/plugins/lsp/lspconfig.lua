return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        -- required for v2 flow
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",

        { "antosha417/nvim-lsp-file-operations", config = true },
        { "folke/neodev.nvim",                   opts = {} },
    },
    config = function()
        -- requires
        local lspconfig = require("lspconfig")
        local mason = require("mason")
        local mason_lspconfig = require("mason-lspconfig")

        -- capabilities for blink.cmp
        local capabilities = require('blink.cmp').get_lsp_capabilities()

        -- diagnostic signs (per-severity) -- Fix for deprecated `vim.lsp.diagnostic` API
        local signs = {
            [vim.diagnostic.severity.ERROR] = { text = " ", numhl = "DiagnosticSignError", linehl = "" },
            [vim.diagnostic.severity.WARN]  = { text = " ", numhl = "DiagnosticSignWarn", linehl = "" },
            [vim.diagnostic.severity.HINT]  = { text = "󰠠 ", numhl = "DiagnosticSignHint", linehl = "" },
            [vim.diagnostic.severity.INFO]  = { text = " ", numhl = "DiagnosticSignInfo", linehl = "" },
        }

        vim.diagnostic.config({
            signs         = signs,
            virtual_text  = true,
            underline     = true,
            severity_sort = true,
        })
        -- init mason first
        mason.setup()

        -- (optional) custom server: azure_pipelines_ls (not in core lspconfig)
        do
            local configs = require("lspconfig.configs")
            if not configs.azure_pipelines_ls then
                configs.azure_pipelines_ls = {
                    default_config = {
                        cmd = { "azure-pipelines-language-server", "--stdio" },
                        -- include yaml/yml so the LS can attach if you don't set a custom ft
                        filetypes = { "azure-pipelines", "azure-pipelines.yml", "pipelines", "yaml", "yml" },
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
                    },
                }
            end
        end

        -- mason-lspconfig v2: use handlers inside setup()
        mason_lspconfig.setup({
            ensure_installed = {
                -- keep every server you listed
                "svelte",
                "graphql",
                "emmet_ls",
                "lua_ls",
                "tailwindcss",
                "eslint",
                "gopls",
                "yamlls",
                "csharp_ls",
                "golangci_lint_ls",
                "jedi_language_server",
                "terraformls",
                "powershell_es",
                "pylsp",
                "pyright",
                "dockerls",
                "html",
                "astro",
                "markdown_oxide",
                "harper_ls",
                -- azure_pipelines_ls is custom; mason won't install it automatically
            },
            automatic_installation = true,

            handlers = {
                -- default for any server not overridden below
                function(server_name)
                    if lspconfig[server_name] then
                        lspconfig[server_name].setup({ capabilities = capabilities })
                    end
                end,

                -- ===== per-server overrides (kept from your config) =====

                svelte = function()
                    lspconfig.svelte.setup({
                        capabilities = capabilities,
                        on_attach = function(client, _)
                            vim.api.nvim_create_autocmd("BufWritePost", {
                                pattern = { "*.js", "*.ts" },
                                callback = function(ctx)
                                    client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
                                end,
                            })
                        end,
                    })
                end,

                graphql = function()
                    lspconfig.graphql.setup({
                        capabilities = capabilities,
                        filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
                    })
                end,

                emmet_ls = function()
                    lspconfig.emmet_ls.setup({
                        capabilities = capabilities,
                        filetypes = {
                            "html", "typescriptreact", "javascriptreact",
                            "css", "sass", "scss", "less", "svelte",
                        },
                    })
                end,

                lua_ls = function()
                    lspconfig.lua_ls.setup({
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                runtime = {
                                    version = "LuaJIT", -- Neovim uses LuaJIT
                                },
                                diagnostics = {
                                    globals = { "vim" },
                                },
                                workspace = {
                                    library = vim.api.nvim_get_runtime_file("", true),
                                    checkThirdParty = false,
                                },
                                completion = {
                                    callSnippet = "Replace",
                                },
                            },
                        },
                    })
                end,


                tailwindcss = function()
                    lspconfig.tailwindcss.setup({
                        capabilities = capabilities,
                        settings = {
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
                        },
                    })
                end,

                eslint = function()
                    lspconfig.eslint.setup({
                        root_dir = lspconfig.util.root_pattern(
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

                gopls = function()
                    lspconfig.gopls.setup({
                        capabilities = capabilities,
                        cmd = { "gopls" },
                        filetypes = { "go", "gomod", "go.mod", "gowork", "gotmpl" },
                        root_dir = lspconfig.util.root_pattern("go.mod", ".git", "go.work"),
                        settings = {
                            gopls = {
                                completeUnimported = true,
                                usePlaceholders = true,
                                analyses = { unusedparams = true },
                                staticcheck = true,
                            },
                        },
                    })
                end,

                yamlls = function()
                    lspconfig.yamlls.setup({
                        capabilities = capabilities,
                        settings = {
                            yaml = {
                                schemaStore = { enable = true }, -- prefer maintained store
                                schemas = {
                                    kubernetes = {
                                        "/*.yaml", "/*.yml",
                                        "kustomization.yaml", "kustomization.yml", "kustomization",
                                        "manifests/*.yaml",
                                    },
                                },
                                keyOrdering = false,
                            },
                        },
                    })
                end,

                csharp_ls = function()
                    lspconfig.csharp_ls.setup({ capabilities = capabilities })
                end,

                golangci_lint_ls = function()
                    lspconfig.golangci_lint_ls.setup({ capabilities = capabilities })
                end,

                jedi_language_server = function()
                    lspconfig.jedi_language_server.setup({ capabilities = capabilities })
                end,

                terraformls = function()
                    lspconfig.terraformls.setup({
                        capabilities = capabilities,
                        filetypes = { "terraform", "tf" },
                        root_dir = lspconfig.util.root_pattern(".git", ".terraform", "terraform.tf", "main.tf", "data.tf"),
                    })
                    vim.api.nvim_create_autocmd({ "BufWritePre" }, {
                        pattern = { "*.tf", "*.tfvars" },
                        callback = function() vim.lsp.buf.format() end,
                    })
                end,

                powershell_es = function()
                    -- Tip: install "powershell-editor-services" via Mason and wire its Start-EditorServices.ps1 if needed.
                    lspconfig.powershell_es.setup({
                        capabilities = capabilities,
                    })
                end,

                pylsp = function() lspconfig.pylsp.setup({ capabilities = capabilities }) end,
                pyright = function() lspconfig.pyright.setup({ capabilities = capabilities }) end,
                dockerls = function() lspconfig.dockerls.setup({ capabilities = capabilities }) end,
                html = function() lspconfig.html.setup({ capabilities = capabilities }) end,

                astro = function()
                    lspconfig.astro.setup({
                        capabilities = capabilities,
                        -- more forgiving root patterns
                        root_dir = lspconfig.util.root_pattern("astro.config.*", "package.json", ".git"),
                    })
                end,

                markdown_oxide = function()
                    local oxide_capabilities = vim.deepcopy(capabilities)
                    oxide_capabilities.workspace = oxide_capabilities.workspace or {}
                    oxide_capabilities.workspace.didChangeWatchedFiles = {
                        dynamicRegistration = true,
                    }
                    lspconfig.markdown_oxide.setup({
                        capabilities = oxide_capabilities,
                        root_dir = lspconfig.util.root_pattern(".obsidian", ".moxide.toml", ".git"),
                        on_attach = function(client, bufnr)
                            -- refresh codelens on BufEnter and InsertLeave
                            if client.server_capabilities.codeLensProvider then
                                vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
                                    buffer = bufnr,
                                    callback = function()
                                        vim.lsp.codelens.refresh({ bufnr = bufnr })
                                    end,
                                })
                                -- initial refresh
                                vim.lsp.codelens.refresh({ bufnr = bufnr })
                            end
                        end,
                    })
                end,

                harper_ls = function()
                    lspconfig.harper_ls.setup({
                        capabilities = capabilities,
                        filetypes = { "markdown" },
                        settings = {
                            ["harper-ls"] = {
                                linters = {
                                    linking_verbs = false,
                                },
                                ignore_link_title = true,
                            },
                        },
                    })
                end,

                -- custom server handler now that it's registered above
                azure_pipelines_ls = function()
                    lspconfig.azure_pipelines_ls.setup({
                        capabilities = capabilities,
                    })
                end,
            },
        })
    end,
}
