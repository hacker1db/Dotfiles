return {
    {
        "pmizio/typescript-tools.nvim",
        ft = { "typescript", "typescriptreact" },
        dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
        opts = {},
    },
}
-- TODO: Add keymaps if stii needed
--
--         -- typescript specific keymaps (e.g. rename file and update imports)
--         keymap.set("n", "<leader>rf", ":TypescriptRenameFile<CR>") -- rename file and update imports
--         keymap.set("n", "<leader>oi", ":TypescriptOrganizeImports<CR>") -- organize imports (not in youtube nvim video)
--         keymap.set("n", "<leader>ru", ":TypescriptRemoveUnused<CR>") -- remove unused variables (not in youtube nvim video)
