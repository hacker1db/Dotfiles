local opt = vim.opt -- save me time later and stop repeating myself
opt.number = true

-- tabs
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true


-- line wrap
opt.wrap = false


-- serach settings
opt.ignorecase = true
opt.smartcase = true
opt.cursorline = true

-- apperaence
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

-- backsapce key

opt.backspace = "indent,eol,start"


-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register
-- use mouse in all modes
opt.mouse = "a" -- set mouse mode to all modes

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

opt.iskeyword:append("-") -- consider string-string as whole word


opt.hlsearch = true -- highlight search results
opt.title = true -- set terminal title
-- mappings
opt.pastetoggle = "<leader>v"

-- toggle invisible characters
opt.list = true
opt.listchars = {
  tab = "→ ",
  eol = "¬",
  trail = "⋅",
  extends = "❯",
  precedes = "❮"
}
