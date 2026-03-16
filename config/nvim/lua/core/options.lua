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
-- Folding settings (defaults — per-filetype overrides in autocmds/folds.lua)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.foldcolumn = "0"
vim.opt.foldtext = ""
vim.opt.fillchars:append("fold: ")
vim.opt.foldnestmax = 4

-- spell disabled globally — harper-ls handles grammar/spelling for markdown
opt.spell = false
--
--
-- Extra vim stuff
cmd([[filetype plugin indent on]])
-- make the highlighting of tabs and other non-text less annoying
cmd([[highlight SpecialKey ctermfg=19 guifg=#333333]])
cmd([[highlight NonText ctermfg=19 guifg=#333333]])

vim.g.copilot_settings = { selectedCompletionModel = "gpt-4o-copilot" }
