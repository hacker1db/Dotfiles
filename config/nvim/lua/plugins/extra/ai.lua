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
                ["*"] = function()
                    local name = vim.fs.basename(vim.api.nvim_buf_get_name(0))
                    for _, pattern in ipairs({ "^%.env", "^%.localrc$", "^%.netrc$", "%.pem$", "%.key$", "^id_", "credentials" }) do
                        if name:match(pattern) then return false end
                    end
                    return true
                end,
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
        cmd = {
            "CopilotChat",
            "CopilotChatPrompts",
            "CopilotChatModels",
            "CopilotChatOpen",
            "CopilotChatClose",
            "CopilotChatToggle",
            "CopilotChatStop",
            "CopilotChatReset",
            "CopilotChatSave",
            "CopilotChatLoad",
        },
        dependencies = {
            { "zbirenbaum/copilot.lua" },
            { "nvim-lua/plenary.nvim" },
        },
        opts = {
            debug = false,
        },
    },
}
