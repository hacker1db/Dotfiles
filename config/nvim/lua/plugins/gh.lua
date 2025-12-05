return {
    "folke/gh.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("gh").setup({})

        -- Keybindings
        vim.keymap.set("n", "<leader>gh", "<cmd>GH<cr>", { desc = "Open GH (GitHub)" })
        vim.keymap.set("n", "<leader>ghp", "<cmd>GH pulls<cr>", { desc = "GH Pull Requests" })
        vim.keymap.set("n", "<leader>ghi", "<cmd>GH issues<cr>", { desc = "GH Issues" })
        vim.keymap.set("n", "<leader>ghr", "<cmd>GH repos<cr>", { desc = "GH Repositories" })
    end,
}
