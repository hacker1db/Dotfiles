return {
    {
        "saghen/blink.cmp",
        lazy = false,
        dependencies = {
            "rafamadriz/friendly-snippets",
            "L3MON4D3/LuaSnip",
            "moyiz/blink-emoji.nvim",
            "ribru17/blink-cmp-spell",
            "friedow/blink-cmp-zsh",
            "giuxtaposition/blink-cmp-copilot",
            {
                "folke/lazydev.nvim",
                ft = "lua",
            },
        },
        version = "v0.*",
        opts = {
            keymap = {
                preset = "default",
                ["<C-k>"] = { "select_prev", "fallback" },
                ["<C-j>"] = { "select_next", "fallback" },
                ["<C-b>"] = { "scroll_documentation_up", "fallback" },
                ["<C-f>"] = { "scroll_documentation_down", "fallback" },
                ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
                ["<C-e>"] = { "hide", "fallback" },
                ["<CR>"] = { "accept", "fallback" },
                ["<Tab>"] = { "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "snippet_backward", "fallback" },
            },

            appearance = {
                use_nvim_cmp_as_default = true,
                nerd_font_variant = "mono",
            },

            sources = {
                default = { "lazydev", "lsp", "path", "snippets", "buffer", "copilot", "emoji", "spell", "zsh" },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100,
                    },
                    copilot = {
                        name = "copilot",
                        module = "blink-cmp-copilot",
                        score_offset = 100,
                        async = true,
                    },
                    lsp = {
                        name = "LSP",
                        module = "blink.cmp.sources.lsp",
                    },
                    path = {
                        name = "Path",
                        module = "blink.cmp.sources.path",
                        opts = {
                            trailing_slash = false,
                            label_trailing_slash = true,
                            get_cwd = function(context)
                                return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
                            end,
                            show_hidden_files_by_default = true,
                        },
                    },
                    buffer = {
                        name = "Buffer",
                        module = "blink.cmp.sources.buffer",
                    },
                    emoji = {
                        module = "blink-emoji",
                        name = "Emoji",
                        score_offset = -5,
                        opts = {
                            insert = true,
                        },
                    },
                    spell = {
                        name = "Spell",
                        module = "blink-cmp-spell",
                        score_offset = -10,
                        opts = {
                            enable_in_context = function()
                                return true
                            end,
                        },
                    },
                    zsh = {
                        name = "zsh",
                        module = "blink-cmp-zsh",
                    },
                },
            },

            snippets = {
                preset = "luasnip",
            },

            completion = {
                accept = {
                    auto_brackets = {
                        enabled = true,
                    },
                },
                menu = {
                    border = "rounded",
                    auto_show = true,
                    max_height = 15,
                    draw = {
                        treesitter = { "lsp" },
                        columns = {
                            { "kind_icon" },
                            { "label", "label_description", gap = 1 },
                            { "kind" },
                        },
                    },
                },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 200,
                    window = {
                        border = "rounded",
                        max_height = 15,
                    },
                },
                ghost_text = {
                    enabled = true,
                },
            },

            signature = {
                enabled = true,
                window = {
                    border = "rounded",
                },
            },
        },
        opts_extend = { "sources.default" },

        config = function(_, opts)
            require("luasnip.loaders.from_vscode").lazy_load()
            require("luasnip.loaders.from_lua").lazy_load({
                paths = { vim.fn.stdpath("config") .. "/luasnippets" },
            })
            require("blink.cmp").setup(opts)
        end,
    },
}
