require("core.options")
require("core.keymaps")

require("core.lazy")
require("plugins.colorscheme")
-- import plugin's
require("plugins.comment")
require("plugins.nvimtree")
require("plugins.lualine")
require("plugins.telescope")
require("plugins.nvim-cmp")
require("plugins.treesitter")
require("plugins.autopair")
require("plugins.lspconfig")
require("plugins.mason")
require("plugins.formatter")
require("plugins.gitsigns")
require("plugins.indent")
require("plugins.devicons")
require("plugins.gopher")
require("plugins.obsidian")
require("plugins.todo")
require("plugins.completion")
require("plugins.terraform")

-- TODO: convert this to lazy

--     -- Markdown files
--         "iamcco/markdown-preview.nvim",
--         run = function()
--             vim.fn["mkdp#util#install"]()
--         end,

--     -- python
--     "jmcomets/vim-pony",
--     "Vimjas/vim-python-pep8-indent",

--     -- managing & installing lsp servers, linters & formatters
--     "williamboman/mason.nvim", -- in charge of managing lsp servers, linters & formatters
--     "williamboman/mason-lspconfig.nvim", -- bridges gap b/w mason & lspconfig

--     -- configuring lsp servers
--     "neovim/nvim-lspconfig", -- easily configure language servers

--     "hrsh7th/cmp-nvim-lsp", -- for autocompletion

--     "jose-elias-alvarez/typescript.nvim", -- additional functionality for typescript server (e.g. rename file & update imports)
--     "onsails/lspkind.nvim", -- vs-code like icons for autocompletion

--     -- formatting & linting
--     "nvimtools/none-ls.nvim", -- configure formatters & linters
--     "jayp0521/mason-null-ls.nvim", -- bridges gap b/w mason & null-ls

--     -- treesitter configuration
--     {
--         "nvim-treesitter/nvim-treesitter",
--         run = function()
--             require("nvim-treesitter.install").update({ with_sync = true })
--         end,
--     },

--     -- auto closing
--     { "windwp/nvim-ts-autotag", after = "nvim-treesitter" }, -- autoclose tags

--     {
--         "themaxmarchuk/tailwindcss-colors.nvim",
--         -- load only on require("tailwindcss-colors")
--         module = "tailwindcss-colors",
--         -- run the.init function after plugin is loaded
--         config = function()
--             -- pass config options here (or nothing to use defaults)
--             require("tailwindcss-colors").init()
--         end,
--         ft = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "astro" },
--     },

--     -- git integration
--     "jonarrien/telescope-cmdline.nvim",
-- }
--
--
