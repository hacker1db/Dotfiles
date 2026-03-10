return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        build = ":Copilot auth",
        event = "InsertEnter",
        opts = {
            suggestion = {
                enabled = true,
                auto_trigger = true,
                debounce = 75,
                keymap = {
                    accept = "<Tab>",
                    next = "<M-]>",
                    prev = "<M-[>",
                    dismiss = "<C-]>",
                },
            },
            panel = {
                enabled = false,
            },
            filetypes = {
                ["*"] = true,
                TelescopePrompt = false,
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
