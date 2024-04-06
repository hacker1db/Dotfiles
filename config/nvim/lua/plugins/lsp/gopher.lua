return {

    "olexsmir/gopher.nvim",
    dependencies = { -- dependencies
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    ft = { "go" },
    config = function()
        require("gopher").setup({
            commands = {
                go = "go",
                gomodifytags = "gomodifytags",
                gotests = "~/go/bin/gotests", -- also you can set custom command path
                impl = "impl",
                iferr = "iferr",
            },
        })
    end,
    build = function()
        vim.cmd([[slient! GoInstallDeps]])
    end,
}
