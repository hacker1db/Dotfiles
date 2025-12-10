local opt = vim.opt -- save me time later and stop repeating myself
local cmd = vim.cmd
local api = vim.api
vim.g.mapleader = ";"
vim.g.maplocalleader = ";"
vim.lsp.set_log_level("off") -- set log level to off

opt.syntax = "enable"
opt.number = true
-- tabs
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.shiftwidth = 4
opt.autoindent = true
opt.conceallevel = 2
opt.relativenumber = true
-- line wrap
opt.wrap = false

-- serach settings
opt.ignorecase = true
opt.smartcase = true
opt.cursorline = true

-- apperaence
opt.termguicolors = true
opt.signcolumn = "yes"
vim.opt.colorcolumn = "80"
-- backsapce key
opt.backspace = "indent,eol,start"

-- clipboard
opt.clipboard:append("unnamedplus", "unnamed") -- use system clipboard as default register
-- use mouse in all modes
opt.mouse = "a"                                -- set mouse mode to all modes

-- split windows
opt.splitright = true     -- split vertical window to the right
opt.splitbelow = true     -- split horizontal window to the bottom

opt.iskeyword:append("-") -- consider string-string as whole word

opt.hlsearch = true       -- highlight search results
opt.title = true          -- set terminal title

-- toggle invisible characters
opt.list = true
opt.listchars:append("space:⋅")
opt.listchars = {
    tab = "→ ",
    eol = "¬",
    trail = "⋅",
    extends = "❯",
    precedes = "❮",
}
-- Folding settings
local M = {}
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
-- markdown folding
vim.g.vim_markdown_folding_disabled = 0
vim.g.vim_markdown_folding_level = 6
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "MarkdownFold()"
-- general folding settings
vim.opt.foldlevel = 99
vim.opt.foldenable = true
vim.opt.foldcolumn = "0"
vim.opt.foldtext = ""
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 1
vim.opt.foldnestmax = 4
-- powerhsell folding settings
vim.g.ps1_nofold_blocks = 1
vim.g.ps1_nofold_sig = 1
vim.opt.foldmethod = "syntax"

function M.nvim_create_augroups(definitions)
    for group_name, definition in pairs(definitions) do
        api.nvim_command('augroup ' .. group_name)
        api.nvim_command('autocmd!')
        for _, def in ipairs(definition) do
            local command = table.concat(vim.tbl_flatten { 'autocmd', def }, ' ')
            api.nvim_command(command)
        end
        api.nvim_command('augroup END')
    end
end

local autoCommands = {
    -- other autocommands
    open_folds = {
        { "BufReadPost,FileReadPost", "*", "normal zR" }
    }
}

M.nvim_create_augroups(autoCommands)

-- auto set spell
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, { command = "setlocal spell spelllang=en_us" })
opt.spelllang = "en_us"
opt.spell = true
opt.spelloptions = "camel"
--
--
-- Extra vim stuff
cmd([[filetype plugin indent on]])
-- make the highlighting of tabs and other non-text less annoying
cmd([[highlight SpecialKey ctermfg=19 guifg=#333333]])
cmd([[highlight NonText ctermfg=19 guifg=#333333]])

vim.g.copilot_settings = { selectedCompletionModel = "gpt-4o-copilot" }
