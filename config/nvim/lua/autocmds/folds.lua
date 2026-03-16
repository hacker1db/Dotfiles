-- Per-filetype fold overrides
local augroup = vim.api.nvim_create_augroup("FiletypeFolds", { clear = true })

-- Markdown: treesitter foldexpr + auto-close folds after delay (skip daily notes)
vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "markdown",
    callback = function(ev)
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
        vim.wo.foldlevel = 99

        -- Auto-close folds after a short delay, but skip daily notes
        local path = vim.api.nvim_buf_get_name(ev.buf)
        if path:match("Daily Stuff") then
            return
        end

        vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(ev.buf) and vim.bo[ev.buf].filetype == "markdown" then
                vim.wo.foldlevel = 1
            end
        end, 100)
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
