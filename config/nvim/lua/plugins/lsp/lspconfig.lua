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
        local mason_lspconfig = require("mason-lspconfig")

        -- capabilities for blink.cmp
        local capabilities = require('blink.cmp').get_lsp_capabilities()

        -- diagnostic signs (per-severity) -- Fix for deprecated `vim.lsp.diagnostic` API
        local signs = {
            [vim.diagnostic.severity.ERROR] = { text = " ", numhl = "DiagnosticSignError", linehl = "" },
            [vim.diagnostic.severity.WARN]  = { text = " ", numhl = "DiagnosticSignWarn", linehl = "" },
            [vim.diagnostic.severity.HINT]  = { text = "󰠠 ", numhl = "DiagnosticSignHint", linehl = "" },
            [vim.diagnostic.severity.INFO]  = { text = " ", numhl = "DiagnosticSignInfo", linehl = "" },
        }

        vim.diagnostic.config({
            signs         = signs,
            virtual_text  = true,
            underline     = true,
            severity_sort = true,
        })

        -- mason-lspconfig v2 ignores `handlers`; configure servers through vim.lsp.config
        -- before setup() so automatic_enable starts them with these settings.
        -- default for every server
        vim.lsp.config("*", { capabilities = capabilities })

        -- ===== per-server overrides (kept from your config) =====
        local servers = {
            svelte = {
                on_attach = function(client, _)
                    vim.api.nvim_create_autocmd("BufWritePost", {
                        pattern = { "*.js", "*.ts" },
                        callback = function(ctx)
                            client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
                        end,
                    })
                end,
            },

            graphql = {
                filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
            },

            emmet_ls = {
                filetypes = {
                    "html", "typescriptreact", "javascriptreact",
                    "css", "sass", "scss", "less", "svelte",
                },
            },

            lua_ls = {
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
            },

            tailwindcss = {
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
            },

            eslint = {
                root_markers = { "eslint.config.js", ".eslintrc.js", ".eslintrc.json", ".eslintrc" },
                on_attach = function(_, bufnr)
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = bufnr,
                        command = "EslintFixAll",
                    })
                end,
            },

            gopls = {
                cmd = { "gopls" },
                filetypes = { "go", "gomod", "go.mod", "gowork", "gotmpl" },
                root_markers = { "go.mod", ".git", "go.work" },
                settings = {
                    gopls = {
                        completeUnimported = true,
                        usePlaceholders = true,
                        analyses = { unusedparams = true },
                        staticcheck = true,
                    },
                },
            },

            yamlls = {
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
            },

            terraformls = {
                filetypes = { "terraform", "tf" },
                root_markers = { ".git", ".terraform", "terraform.tf", "main.tf", "data.tf" },
            },

            astro = {
                -- more forgiving root patterns
                root_markers = { "astro.config.*", "package.json", ".git" },
            },

            markdown_oxide = {
                capabilities = {
                    workspace = {
                        didChangeWatchedFiles = { dynamicRegistration = true },
                    },
                },
                root_markers = { ".obsidian", ".moxide.toml", ".git" },
            },

            harper_ls = {
                filetypes = { "markdown" },
                root_markers = { ".obsidian", ".moxide.toml", ".git" },
                settings = {
                    ["harper-ls"] = {
                        linters = {
                            linking_verbs = false,
                        },
                        ignore_link_title = true,
                    },
                },
            },

            -- (optional) custom server: azure_pipelines_ls
            azure_pipelines_ls = {
                cmd = { "azure-pipelines-language-server", "--stdio" },
                -- include yaml/yml so the LS can attach if you don't set a custom ft
                filetypes = { "azure-pipelines", "azure-pipelines.yml", "pipelines", "yaml", "yml" },
                root_markers = { ".git", ".azure-pipelines", "azure-pipelines.yml" },
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

        for name, config in pairs(servers) do
            vim.lsp.config(name, config)
        end

        vim.api.nvim_create_autocmd({ "BufWritePre" }, {
            pattern = { "*.tf", "*.tfvars" },
            callback = function() vim.lsp.buf.format() end,
        })

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
            -- installed servers are enabled via vim.lsp.enable() using the configs above
            automatic_enable = true,
        })
    end,
}
