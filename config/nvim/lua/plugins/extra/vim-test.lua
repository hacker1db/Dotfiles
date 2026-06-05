return {
    "vim-test/vim-test",
    keys = {
        { "<leader>tn", "<cmd>TestNearest<CR>", desc = "Test nearest" },
        { "<leader>tf", "<cmd>TestFile<CR>", desc = "Test file" },
        { "<leader>ts", "<cmd>TestSuite<CR>", desc = "Test suite" },
        { "<leader>tl", "<cmd>TestLast<CR>", desc = "Test last" },
        { "<leader>tv", "<cmd>TestVisit<CR>", desc = "Test visit" },
    },
    cmd = { "TestNearest", "TestFile", "TestSuite", "TestLast", "TestVisit" },
    config = function()
        vim.g["test#strategy"] = "neovim"
        vim.g["test#neovim#term_position"] = "belowright 15"
    end,
}
