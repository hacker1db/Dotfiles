-- leader key ; (was space previously)
vim.g.mapleader = ";"
local keymap = vim.keymap -- for conciseness local opts = { noremap = true, silent = true }
---------------------
-- General Keymaps
---------------------
-- make quitting stuff easier map command Wq to :wq
vim.cmd("command! Wq wq!")
-- save all buffers and quit neovim
keymap.set("n", "<leader>qa", ":wa<CR>:qa<CR>", { desc = "Save all buffers and quit" })
-- indentation carry
keymap.set("v", "<leader>[", "<gv", { desc = "indent selection left" })
keymap.set("v", "<leader>]", ">gv", { desc = "indent selection right" })

-- use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "exit insert mode with jk" })
keymap.set("n", "<leader>q", ":q!<CR>", { desc = "quit" }) -- quit

-- clear search highlights
keymap.set("n", "<space>", ":nohl<CR>", { desc = "Clear search highlights" })

-- window management
-- nvim-tree

keymap.set("n", "<leader>\\", "<C-w>v", { desc = "split virtically" })
keymap.set("n", "<leader>-", "<C-w>s", { desc = "split horizontally" })
keymap.set("n", "<leader>=", "<C-w>=", { desc = "make split windows equal width & height" })
keymap.set("n", "<leader>w", ":close<CR>", { desc = "close current buffer or tab" })
keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>", { desc = "Tmux navigate left" })
keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>", { desc = "Tmux navigate down" })
keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>", { desc = "Tmux navigate up" })
keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>", { desc = "Tmux navigate right" })
keymap.set("n", "<C-\\>", "<cmd>TmuxNavigatePrevious<CR>", { desc = "Tmux navigate previous" })

keymap.set("n", ",,", ":w<CR>", { desc = "Save file" })
keymap.set("n", "<leader>cf", ":lua vim.lsp.buf.format()<CR>", { desc = "Format file" })
keymap.set("n", "<leader>s", ":so<CR>", { desc = "Source file" })
keymap.set("n", "<leader>yf", ':let @+=expand("<cfile>:p")<CR>', { desc = "Yank file path under cursor" })

-- window management buffers
keymap.set("n", "bn", "<cmd>bn<CR>", { desc = "Go to next buffer" }) -- go to next buffer
keymap.set("n", "bp", "<cmd>bp<CR>", { desc = "Go to previous buffer" }) -- go to previous buffer
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
keymap.set("n", "<leader>ee", "<cmd>GoIfErr<cr>", { silent = true, noremap = true })

-- telescope git commands (keep telescope for git, mini.pick doesn't have built-in git support)
keymap.set("n", "<leader>gc", "<cmd>Telescope git_commits<cr>", { desc = "Telescope git commit search" })
keymap.set("n", "<leader>gfc", "<cmd>Telescope git_bcommits<cr>", { desc = "Telescope show current commits from file" })
keymap.set("n", "<leader>gb", "<cmd>Telescope git_branches<cr>", { desc = "Telescope show branches" })
keymap.set("n", "<leader>gs", "<cmd>Telescope git_status<cr>", { desc = "Telescope show git status" })
-- todo comments (keep TodoTelescope for now)
keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })

-- restart lsp server
keymap.set("n", "<leader>rs", ":LspRestart<CR>") -- mapping to restart lsp if necessary

-- Markdown key mapping
keymap.set("n", "<leader>mp", ":MarkdownPreview<CR>")
keymap.set("n", "<leader>mps", ":MarkdownPreviewStop<CR>")

-- undotree
keymap.set("n", "<leader>u", ":UndotreeToggle<CR>", { desc = "Toggle Undotree" })

-- gitsigns
keymap.set("n", "<leader>gd", function()
    require("gitsigns").diffthis()
end, { desc = "Git diff this" })
keymap.set("n", "<leader>gD", function()
    require("gitsigns").diffthis("~")
end, { desc = "Git diff this ~" })

-- mini.diff
keymap.set("n", "<leader>go", function()
    require("mini.diff").toggle_overlay()
end, { desc = "Toggle git overlay (mini.diff)" })
-- Git Stuff
keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", {})
keymap.set("n", "<leader>gB", ":Gitsigns toggle_current_line_blame<CR>", { desc = "Toggle git blame" })

-- Snacks explorer
-- Toggle logic: if an explorer buffer is visible, close it; otherwise open/reveal
keymap.set("n", "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", { desc = "Toggle Pin" })
keymap.set("n", "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", { desc = "Delete Non-Pinned Buffers" })
keymap.set("n", "<leader>br", "<Cmd>BufferLineCloseRight<CR>", { desc = "Delete Buffers to the Right" })
keymap.set("n", "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", { desc = "Delete Buffers to the Left" })
keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
keymap.set("n", "[b", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
keymap.set("n", "]b", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
keymap.set("n", "[B", "<cmd>BufferLineMovePrev<cr>", { desc = "Move buffer prev" })
keymap.set("n", "]B", "<cmd>BufferLineMoveNext<cr>", { desc = "Move buffer next" })
-- trouble
keymap.set("n", "<leader>xx", "<cmd>TroubleToggle<cr>", { silent = true, noremap = true })
keymap.set("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", { silent = true, noremap = true })
keymap.set("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", { silent = true, noremap = true })
keymap.set("n", "<leader>xl", "<cmd>TroubleToggle loclist<cr>", { silent = true, noremap = true })
keymap.set("n", "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", { silent = true, noremap = true })
keymap.set("n", "gR", "<cmd>TroubleToggle lsp_references<cr>", { silent = true, noremap = true })
keymap.set("n", "<leader>xt", "<cmd>TodoTrouble<CR>", { desc = "Open todos in trouble" })

-- lsp config keymaps
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf, silent = true }

        -- set keybinds
        opts.desc = "Show LSP references"
        keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
    end,
})

keymap.set("n", "]t", function()
    require("todo-comments").jump_next()
end, { desc = "Next todo comment" })
keymap.set("n", "[t", function()
    require("todo-comments").jump_prev()
end, { desc = "Previous todo comment" })
keymap.set("n", "<leader>ds", function()
    require("dap").continue()
end, { desc = "Debug: Start/Continue" })
keymap.set("n", "<F1>", function()
    require("dap").step_into()
end, { desc = "Debug: Step Into" })
keymap.set("n", "<F2>", function()
    require("dap").step_over()
end, { desc = "Debug: Step Over" })
keymap.set("n", "<F3>", function()
    require("dap").step_out()
end, { desc = "Debug: Step Out" })
keymap.set("n", "<leader>b", function()
    require("dap").toggle_breakpoint()
end, { desc = "Debug: Toggle Breakpoint" })
keymap.set("n", "<leader>B", function()
    require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: Set Breakpoint" })
keymap.set("n", "<F7>", function()
    require("dapui").toggle()
end, { desc = "Debug: See last session result." })

-- Octo keymaps
keymap.set("n", "<leader>o", "<cmd>Octo<cr>", { desc = "Octo open" })
