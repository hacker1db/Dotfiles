return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-buffer", -- source for text in buffer
        "hrsh7th/cmp-path",   -- source for file system paths
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-nvim-lua",
        { "hrsh7th/cmp-vsnip",                      after = "nvim-cmp" },
        "hrsh7th/cmp-emoji",            -- emoji completion
        "f3fora/cmp-spell",             -- spell completion
        "L3MON4D3/LuaSnip",             -- snippet engine
        "saadparwaiz1/cmp_luasnip",     -- for autocompletion
        "rafamadriz/friendly-snippets", -- useful snippets
        "zbirenbaum/copilot-cmp",
        "onsails/lspkind.nvim",         -- vs-code like pictograms
        { "roobert/tailwindcss-colorizer-cmp.nvim", config = true },
        "onsails/lspkind.nvim",         -- vs-code like pictograms
    },
    config = function()
        local cmp = require("cmp")
        local lspkind = require("lspkind")
        local tailwind_formatter = require("tailwindcss-colorizer-cmp").formatter
        local luasnip = require("luasnip")
        -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
        require("luasnip.loaders.from_vscode").lazy_load()

        vim.o.completeopt = "menu,menuone,noselect"

        cmp.setup({
            ghost_text = { enabled = true },
            snippet = { -- configure how nvim-cmp interacts with snippet engine
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                    vim.fn["vsnip#anonymous"](args.body)
                end,
            },
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
                ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
                ["<C-e>"] = cmp.mapping.close(),        -- close completion window
                ["<CR>"] = cmp.mapping.confirm({ select = false }),
            }),
            -- sources for autocompletion
            sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "luasnip" },    -- snippets
                { name = "buffer" },     -- text within current buffer
                { name = "path" },       -- file system paths
                { name = "copilot" },    -- copilot suggestions
                { name = "emoji" },      -- emoji completion
                { name = "treesitter" }, -- treesitter completion
                { name = "spell" },      -- spell completion
                { name = "zsh" },        -- zsh completion
                { name = "vsnip" },      -- snippets from vsnip
                { name = "nvim_lua" },   -- lua autocompletion
            }),
            -- configure lspkind for vs-code like pictograms in completion menu
            formatting = {
                fields = { cmp.ItemField.Menu, cmp.ItemField.Abbr, cmp.ItemField.Kind },
                format = lspkind.cmp_format({
                    with_text = true,
                    show_labelDetails = true,
                    maxwidth = 50,
                    ellipsis_char = "...",
                    menu = {
                        nvim_lsp = "ﲳ",
                        nvim_lua = "",
                        luasnip = "",
                        path = "ﱮ",
                        buffer = "﬘",
                        vsnip = "",
                        treesitter = "",
                        zsh = "",
                        spell = "暈",
                    },
                    before = tailwind_formatter,
                }),
            },
            experimental = { native_menu = false, ghost_text = { enabled = true } },
        })
    end,
}
