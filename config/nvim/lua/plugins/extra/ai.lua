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
}
