return {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    dependencies = {
        -- Required.
        "nvim-lua/plenary.nvim",
    },
    opts = {
        workspaces = {
            {
                name = "personal",
                path = "/Users/hacker1db/notes/SecondBrain",
            },
            {
                name = "youtube",
                path = "~/notes/Youtube",
            },
        },
    },
}
