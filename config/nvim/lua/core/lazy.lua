local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)


require("lazy").setup({ { import = "plugins" } }, {
    install = {
        colorscheme = { "dracula" },
    },
    checker = {
        enabled = true,
        notify = false,
    },
    change_detection = {
        notify = false,
    },
})




-- local plugins = {

--     "github/copilot.vim",
--     "tpope/vim-sleuth",
--     "hashivim/vim-terraform", -- terraform
--     "nvim-lua/plenary.nvim", -- lua functions that many plugins
--     "szw/vim-maximizer", -- maximizes and restores current window
--     "lukas-reineke/indent-blankline.nvim",
--     -- essential plugins
--     "tpope/vim-surround", -- add, delete, change surroundings (it's awesome)
--     "vim-scripts/ReplaceWithRegister", -- replace with register contents using motion (gr + motion)
--     -- commenting with gc
--     "numToStr/Comment.nvim",
--     "JoosepAlviste/nvim-ts-context-commentstring",

--     -- language plugins
--     {
--         "olexsmir/gopher.nvim",
--         dependencies = { -- dependencies
--             "nvim-lua/plenary.nvim",
--             "nvim-treesitter/nvim-treesitter",
--             build = function()
--                 vim.cmd("silent! GoInstallDeps")
--             end,
--         },
--         ft = { "go" },
--     },

--     -- Markdown files
--         "iamcco/markdown-preview.nvim",
--         run = function()
--             vim.fn["mkdp#util#install"]()
--         end,

--     -- python
--     "jmcomets/vim-pony",
--     "Vimjas/vim-python-pep8-indent",

--     "simrat39/rust-tools.nvim",

--     -- Debugging
--     "mfussenegger/nvim-dap",
--     "leoluz/nvim-dap-go",

--     -- fuzzy finding w/ telescope
--     { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },

--     { "nvim-telescope/telescope.nvim", branch = "0.1.x" }, -- fuzzy finder

--     "nvim-telescope/telescope-ui-select.nvim", -- for showing lsp code actions

--     {
--         "smjonas/inc-rename.nvim",
--         config = function()
--             require("inc_rename").setup()
--         end,
--     },

--     -- autocompletion
--     "hrsh7th/nvim-cmp", -- completion plugin
--     "hrsh7th/cmp-buffer", -- source for text in buffer
--     "hrsh7th/cmp-path", -- source for file system paths

--     -- snippets
--     "L3MON4D3/LuaSnip", -- snippet engine
--     "saadparwaiz1/cmp_luasnip", -- for autocompletion
--     "rafamadriz/friendly-snippets", -- useful snippets

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


