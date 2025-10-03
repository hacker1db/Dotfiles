return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        build = ":Copilot auth",
        event = "InsertEnter",
        opts = {
            suggestion = {
                enabled = false,
            },
            panel = {
                enabled = false,
            },
        },
    },
    {
        "giuxtaposition/blink-cmp-copilot",
        dependencies = { "zbirenbaum/copilot.lua" },
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        branch = "main",
        dependencies = {
            { "zbirenbaum/copilot.lua" },
            { "nvim-lua/plenary.nvim" },
        },
        opts = {
            debug = false,
        },
    },
}
