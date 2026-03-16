return {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "echasnovski/mini.icons",
    },
    opts = {
        symbol_in_winbar = {
            enable = true,
        },
        lightbulb = {
            enable = true,
            sign = true,
            virtual_text = false,
        },
        code_action = {
            show_server_name = true,
            extend_gitsigns = false,
        },
        rename = {
            in_select = false,
            auto_save = true,
        },
        hover = {
            open_cmd = "!open",
        },
        outline = {
            layout = "float",
        },
    },
    keys = {
        { "<leader>ca", "<cmd>Lspsaga code_action<CR>",          mode = { "n", "v" }, desc = "Code action (Lspsaga)" },
        { "<leader>rn", "<cmd>Lspsaga rename<CR>",               desc = "Rename (Lspsaga)" },
        { "K",          "<cmd>Lspsaga hover_doc<CR>",            desc = "Hover doc (Lspsaga)" },
        { "gp",         "<cmd>Lspsaga peek_definition<CR>",      desc = "Peek definition (Lspsaga)" },
        { "gP",         "<cmd>Lspsaga peek_type_definition<CR>", desc = "Peek type definition (Lspsaga)" },
        { "<leader>lo", "<cmd>Lspsaga outline<CR>",              desc = "Outline (Lspsaga)" },
    },
}
