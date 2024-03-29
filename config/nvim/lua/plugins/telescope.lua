return {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        "nvim-tree/nvim-web-devicons",
        "nvim-telescope/telescope-ui-select.nvim",
        "jonarrien/telescope-cmdline.nvim",
    },
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")

        telescope.setup({
            extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown({}),
                },
                cmdline = {
                    picker = {
                        layout_config = {
                            width = 120,
                            height = 25,
                        },
                    },
                    mappings = {
                        complete = "<Tab>",
                        run_selection = "<C-CR>",
                        run_input = "<CR>",
                    },
                },
            },
            defaults = {
                path_display = { "truncate " },
                mappings = {
                    i = {
                        ["<C-k>"] = actions.move_selection_previous, -- move to prev result
                        ["<C-j>"] = actions.move_selection_next, -- move to next result
                        ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                    },
                },
            },
        })
        telescope.load_extension("fzf")
        telescope.load_extension("ui-select")
        -- telescope.load_extension("cmdline")
    end,
}
