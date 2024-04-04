-- set leader key to space
vim.g.mapleader = ";"
local keymap = vim.keymap -- for conciseness local opts = { noremap = true, silent = true }
---------------------
-- General Keymaps
---------------------

-- indentation carry
keymap.set("v", "<leader>[", "<gv", { desc = "indent selection left" })
keymap.set("v", "<leader>]", ">gv", { desc = "indent selection right" })

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "exit insert mode with jk" })

-- clear search highlights
keymap.set("n", "<space>", ":nohl<CR>", { desc = "Clear search highlights" })

-- window management
keymap.set("n", "<leader>\\", "<C-w>v", { desc = "split virtically" })
keymap.set("n", "<leader>-", "<C-w>s", { desc = "split horizontally" })
keymap.set("n", "<leader>=", "<C-w>=", { desc = "make split windows equal width & height" })
keymap.set("n", "<leader>w", ":close<CR>", { desc = "close current buffer or tab" })

keymap.set("n", ",,", ":w<CR>", { desc = "Save file" })
keymap.set("n", "<leader>ff", ":lua vim.lsp.buf.format()<CR>", { desc = "Format file" })
keymap.set("n", "<leader>s", ":so<CR>", { desc = "Source file" })

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

----------------------
-- Plugin Keybinds
----------------------

-- gopher
-- json tags
keymap.set("n", "<leader>gtj", ":GoTagAdd json<CR>", { desc = "gopher generate json tags" }) -- generate tags for json
-- yaml tags
keymap.set("n", "<leader>gty", ":GoTagAdd yaml<CR>", { desc = "gopher generate json tags" }) -- generate tags for yaml
-- gopher tests and iferr
keymap.set("n", "<leader>gt", ":GoTestsAll<CR>") -- generate tests for current file
keymap.set("n", "<leader>gi", ":GoIfErr<CR>") -- generate if err check for current file

-- telescope
keymap.set("n", "<leader>f", "<cmd>Telescope find_files<cr>", { desc = "Telescope Show files in current directory" }) -- find files within current working directory, respects .gitignore
keymap.set("n", "<leader>fr", "<cmd>Telescope live_grep<cr>", { desc = "Telescope Find string under cursor in cwd" }) -- find string in current working directory as you type
keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Telescope Find current word" }) -- find string under cursor in current working directory
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Telescope show buffers list" }) -- list open buffers in current neovim instance
keymap.set("n", "<leader>fg", "<cmd>Telescope git_files<cr>", { desc = "Telscope list git files" }) -- list git_files
keymap.set("n", ";;", "<cmd>Telescope help_tags<cr>", { desc = "Telescope show help tags" }) -- list available help tags

-- telescope git commands
keymap.set("n", "<leader>gc", "<cmd>Telescope git_commits<cr>", { desc = "Telescope git commit search" }) -- list all git commits (use <cr> to checkout) ["gc" for git commits]
keymap.set("n", "<leader>gfc", "<cmd>Telescope git_bcommits<cr>", { desc = "Telescope show current commits from file" }) -- list git commits for current file/buffer (use <cr> to checkout) ["gfc" for git file commits]
keymap.set("n", "<leader>gb", "<cmd>Telescope git_branches<cr>", { desc = "Telescope show branches" }) -- list git branches (use <cr> to checkout) ["gb" for git branch]
keymap.set("n", "<leader>gs", "<cmd>Telescope git_status<cr>", { desc = "Telescope show git status" }) -- list current changes per file with diff preview ["gs" for git status]
-- telescope todo comments
keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })

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
keymap.set("n", "<leader>xt", "<cmd>TodoTrouble<CR>", { desc = "Open todos in trouble" })

-- Obsidian
-- TODO: Fix key mappings for Obsidian
-- keymap.set("<leader>on", "<cmd>ObsidianNew<cr>", desc = "New Obsidian note", mode = "n" )
-- keymap.set({ "<leader>oo", "<cmd>ObsidianSearch<cr>", desc = "Search Obsidian notes", mode = "n" })
-- keymap.set({ "<leader>os", "<cmd>ObsidianQuickSwitch<cr>", desc = "Quick Switch", mode = "n" })
-- keymap.set({ "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Show location list of backlinks", mode = "n" })
-- keympa.set({ "<leader>ot", "<cmd>ObsidianTemplate<cr>", desc = "Follow link under cursor", mode = "n" })
