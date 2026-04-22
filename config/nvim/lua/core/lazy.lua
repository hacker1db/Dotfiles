local uv = vim.uv or vim.loop
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not uv.fs_stat(lazypath) then
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

require("lazy").setup({
    { import = "plugins.extra" },
    { import = "plugins.git" },
    { import = "plugins.ui" },
    { import = "plugins.lsp" },
    { import = "plugins.mini" },
}, {
    opts = {
        colorscheme = "eldritch",
    },
    install = {
        colorscheme = { "eldritch" },
    },
    checker = {
        enabled = true,
        notify = false,
    },
    change_detection = {
        notify = false,
    },
})
