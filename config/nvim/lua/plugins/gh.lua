return {
    "folke/gh.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("gh").setup({})
    end,
}
