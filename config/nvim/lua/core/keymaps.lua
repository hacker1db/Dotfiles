-- set leader key to space
vim.g.mapleader = ";"
local keymap = vim.keymap -- for conciseness local opts = { noremap = true, silent = true }
---------------------
-- General Keymaps
---------------------

-- indentation carry
keymap.set("v", "<leader>[", "<gv", opts)
keymap.set("v", "<leader>]", ">gv", opts)

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>")

-- clear search highlights
keymap.set("n", "<space>", ":nohl<CR>")

-- delete single character without copying into register
keymap.set("n", "x", '"_x')

-- window management
keymap.set("n", "<leader>\\", "<C-w>v") -- split window vertically
keymap.set("n", "<leader>-", "<C-w>s") -- split window horizontally
keymap.set("n", "<leader>=", "<C-w>=") -- make split windows equal width & height
keymap.set("n", "<leader>w", ":close<CR>") -- close current split window, also close current tab

keymap.set("n", "<leader>t", ":tabnew<CR>") -- open new tab
keymap.set("n", "<leader>tn", ":tabn<CR>") --  go to next tab
keymap.set("n", "<leader>tp", ":tabp<CR>") --  go to previous tab
keymap.set("n", ",,", ":w<CR>")
keymap.set("n", "<leader>ff", ":lua vim.lsp.buf.format()<CR>")
keymap.set("n", "<leader>s", ":so<CR>")

----------------------
-- Plugin Keybinds
----------------------

-- gopher
-- json tags
keymap.set("n", "<leader>gtj", ":GoTagAdd json<CR>") -- generate tags for json
-- yaml tags
keymap.set("n", "<leader>gty", ":GoTagAdd yaml<CR>") -- generate tags for yaml
-- gopher tests and iferr
keymap.set("n", "<leader>gt", ":GoTestsAll<CR>") -- generate tests for current file
keymap.set("n", "<leader>gi", ":GoIfErr<CR>") -- generate if err check for current file

-- vim-maximizer
keymap.set("n", "<leader>sm", ":MaximizerToggle<CR>") -- toggle split window maximization

-- telescope
keymap.set("n", "<leader>f", "<cmd>Telescope find_files<cr>") -- find files within current working directory, respects .gitignore
keymap.set("n", "<leader>fr", "<cmd>Telescope live_grep<cr>") -- find string in current working directory as you type
keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>") -- find string under cursor in current working directory
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>") -- list open buffers in current neovim instance
keymap.set("n", "<leader>fg", "<cmd>Telescope git_files<cr>") -- list git_files
keymap.set("n", ";;", "<cmd>Telescope help_tags<cr>") -- list available help tags

-- telescope git commands
keymap.set("n", "<leader>gc", "<cmd>Telescope git_commits<cr>") -- list all git commits (use <cr> to checkout) ["gc" for git commits]
keymap.set("n", "<leader>gfc", "<cmd>Telescope git_bcommits<cr>") -- list git commits for current file/buffer (use <cr> to checkout) ["gfc" for git file commits]
keymap.set("n", "<leader>gb", "<cmd>Telescope git_branches<cr>") -- list git branches (use <cr> to checkout) ["gb" for git branch]
keymap.set("n", "<leader>gs", "<cmd>Telescope git_status<cr>") -- list current changes per file with diff preview ["gs" for git status]

-- restart lsp server
keymap.set("n", "<leader>rs", ":LspRestart<CR>") -- mapping to restart lsp if necessary

-- Markdown key mapping
keymap.set("n", "<leader>mp", ":MarkdownPreview<CR>")
keymap.set("n", "<leader>mps", ":MarkdownPreviewStop<CR>")

-- Git Stuff
keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", {})
keymap.set("n", "<leader>gt", ":Gitsigns toggle_current_line_blame<CR>", {})

-- twilight
keymap.set("n", "tw", ":Twilight<enter>", { noremap = false })

-- Noice
keymap.set("n", "<leader>nn", ":NoiceDismiss<CR>", { noremap = true })
keymap.set("n", "<leader>ee", "<cmd>GoIfErr<cr>", { silent = true, noremap = true })

-- trouble
keymap.set("n", "<leader>xx", "<cmd>TroubleToggle<cr>", { silent = true, noremap = true })
keymap.set("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", { silent = true, noremap = true })
keymap.set("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", { silent = true, noremap = true })
keymap.set("n", "<leader>xl", "<cmd>TroubleToggle loclist<cr>", { silent = true, noremap = true })
keymap.set("n", "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", { silent = true, noremap = true })
keymap.set("n", "gR", "<cmd>TroubleToggle lsp_references<cr>", { silent = true, noremap = true })

-- Obsidian
-- TODO: Fix key mappings for Obsidian
-- keymap.set("<leader>on", "<cmd>ObsidianNew<cr>", desc = "New Obsidian note", mode = "n" )
-- keymap.set({ "<leader>oo", "<cmd>ObsidianSearch<cr>", desc = "Search Obsidian notes", mode = "n" })
-- keymap.set({ "<leader>os", "<cmd>ObsidianQuickSwitch<cr>", desc = "Quick Switch", mode = "n" })
-- keymap.set({ "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Show location list of backlinks", mode = "n" })
-- keympa.set({ "<leader>ot", "<cmd>ObsidianTemplate<cr>", desc = "Follow link under cursor", mode = "n" })
