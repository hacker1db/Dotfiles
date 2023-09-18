-- auto install packer if not installed
local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
        vim.cmd([[packadd packer.nvim]])
        return true
    end
    return false
end
local packer_bootstrap = ensure_packer() -- true if packer was just installed

-- autocommand that reloads neovim and installs/updates/removes plugins
-- when file is saved
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost packer-setup.lua source <afile> | PackerSync
  augroup end
]])

-- import packer safely
local status, packer = pcall(require, "packer")
if not status then
    return
end

-- add list of plugins to install
return packer.startup(function(use)
    -- packer can manage itself
    use("wbthomason/packer.nvim")
    use("github/copilot.vim")

    use("tpope/vim-sleuth")

    use("hashivim/vim-terraform") -- terraform

    use("nvim-lua/plenary.nvim") -- lua functions that many plugins use

    use("Mofiqul/dracula.nvim") -- preferred colorscheme

    use("christoomey/vim-tmux-navigator") -- tmux & split window navigation

    use("szw/vim-maximizer") -- maximizes and restores current window

    use("lukas-reineke/indent-blankline.nvim")

    -- essential plugins
    use("tpope/vim-surround") -- add, delete, change surroundings (it's awesome)
    use("vim-scripts/ReplaceWithRegister") -- replace with register contents using motion (gr + motion)

    -- commenting with gc
    use("numToStr/Comment.nvim")
    use("JoosepAlviste/nvim-ts-context-commentstring")

    -- file explorer
    use({ "nvim-tree/nvim-tree.lua", requires = "kyazdani42/nvim-web-devicons" })
    -- language plugins
    use({
        "olexsmir/gopher.nvim",
        requires = { -- dependencies
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            build = function()
                vim.cmd("silent! GoInstallDeps")
            end,
        },
        ft = { "go" },
    })

    -- Markdown files
    use({
        "iamcco/markdown-preview.nvim",
        run = function()
            vim.fn["mkdp#util#install"]()
        end,
    })

    -- todo comments
    use({
        "folke/todo-comments.nvim",
        requires = "nvim-lua/plenary.nvim",
        config = function()
            require("todo-comments").setup({})
        end,
    })

    -- trouble set up
    use({
        "folke/trouble.nvim",
        requires = "nvim-tree/nvim-web-devicons",
        config = function()
            require("trouble").setup({
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            })
        end,
    })

    -- pyhton
    use("jmcomets/vim-pony")
    use("Vimjas/vim-python-pep8-indent")

    -- vs-code like icons
    use("kyazdani42/nvim-web-devicons")

    use("simrat39/rust-tools.nvim")

    -- Debugging
    use("mfussenegger/nvim-dap")
    use("leoluz/nvim-dap-go")

    -- statusline
    use("nvim-lualine/lualine.nvim")

    -- fuzzy finding w/ telescope
    use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" }) -- dependency for better sorting performance
    use({ "nvim-telescope/telescope.nvim", branch = "0.1.x" }) -- fuzzy finder
    use({ "nvim-telescope/telescope-ui-select.nvim" }) -- for showing lsp code actions
    use({
        "smjonas/inc-rename.nvim",
        config = function()
            require("inc_rename").setup()
        end,
    })

    -- autocompletion
    use("hrsh7th/nvim-cmp") -- completion plugin
    use("hrsh7th/cmp-buffer") -- source for text in buffer
    use("hrsh7th/cmp-path") -- source for file system paths

    -- snippets
    use("L3MON4D3/LuaSnip") -- snippet engine
    use("saadparwaiz1/cmp_luasnip") -- for autocompletion
    use("rafamadriz/friendly-snippets") -- useful snippets

    -- managing & installing lsp servers, linters & formatters
    use("williamboman/mason.nvim") -- in charge of managing lsp servers, linters & formatters
    use("williamboman/mason-lspconfig.nvim") -- bridges gap b/w mason & lspconfig

    -- configuring lsp servers
    use("neovim/nvim-lspconfig") -- easily configure language servers

    use("hrsh7th/cmp-nvim-lsp") -- for autocompletion

    use("jose-elias-alvarez/typescript.nvim") -- additional functionality for typescript server (e.g. rename file & update imports)
    use("onsails/lspkind.nvim") -- vs-code like icons for autocompletion

    -- formatting & linting
    use("jose-elias-alvarez/null-ls.nvim") -- configure formatters & linters
    use("jayp0521/mason-null-ls.nvim") -- bridges gap b/w mason & null-ls

    -- treesitter configuration
    use({
        "nvim-treesitter/nvim-treesitter",
        run = function()
            require("nvim-treesitter.install").update({ with_sync = true })
        end,
    })

    -- auto closing
    use("windwp/nvim-autopairs") -- autoclose parens, brackets, quotes, etc...
    use({ "windwp/nvim-ts-autotag", after = "nvim-treesitter" }) -- autoclose tags

    use({
        "themaxmarchuk/tailwindcss-colors.nvim",
        -- load only on require("tailwindcss-colors")
        module = "tailwindcss-colors",
        -- run the setup function after plugin is loaded
        config = function()
            -- pass config options here (or nothing to use defaults)
            require("tailwindcss-colors").setup()
        end,
        ft = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "astro" },
    })

    -- git integration
    use("lewis6991/gitsigns.nvim") -- show line modifications on left hand side

    if packer_bootstrap then
        require("packer").sync()
    end
end)
