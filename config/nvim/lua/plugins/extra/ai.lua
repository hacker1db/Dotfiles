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
                keymap = {
                    accept = "<Tab>",
                    select = "<CR>",
                    close = "<Esc>",
                    next = "<C-J>",
                    prev = "<C-K>",
                    dismiss = "<C-X>",
                },
            },
            panel = {
                enabled = false,
            },
        },
    },
    {
        "zbirenbaum/copilot-cmp",
        dependencies = {
            "hrsh7th/nvim-cmp",
        },
        config = true,
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        branch = "canary",
        dependencies = {
            { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
            { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
        },
        opts = {
            debug = true, -- Enable debugging
            -- See Configuration section for rest
        },
        -- See Commands section for default commands if you want to lazy load on them
    },
}
