-- Per-filetype fold overrides
local augroup = vim.api.nvim_create_augroup("FiletypeFolds", { clear = true })

-- Markdown: treesitter foldexpr, folds start open
vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "markdown",
    callback = function()
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo.foldlevel = 99
    end,
})

-- JSON: disable folding entirely
vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = { "json", "jsonc" },
    callback = function()
        vim.wo.foldenable = false
    end,
})

-- PowerShell: syntax-based folding
vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "ps1",
    callback = function()
        vim.g.ps1_nofold_blocks = 1
        vim.g.ps1_nofold_sig = 1
        vim.wo.foldmethod = "syntax"
    end,
})
