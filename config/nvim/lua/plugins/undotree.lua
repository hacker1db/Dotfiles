return {
    "mbbill/undotree",
    config = function()
        -- Set undotree window layout
        vim.g.undotree_WindowLayout = 2

        -- Set undotree window width
        vim.g.undotree_SplitWidth = 30

        -- Enable short timestamps
        vim.g.undotree_ShortIndicators = 1

        -- Set focus to undotree window when opened
        vim.g.undotree_SetFocusWhenToggle = 1

        -- Keybinding to toggle undotree
        vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Toggle Undotree" })
    end,
}
