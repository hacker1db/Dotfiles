return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local nvimtree = require("nvim-tree")

        -- recommended settings from nvim-tree documentation
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
        -- configure nvim-tree
        nvimtree.setup({
            view = {
                width = 35,
                side = "left",
            },

            disable_netrw = false,
            hijack_netrw = true,
            diagnostics = {
                enable = false,
            },
            update_focused_file = {
                enable = true,
                update_cwd = false,
            },
            git = {
                enable = true,
                ignore = false,
            },

            -- disable window_picker for
            -- explorer to work well with
            -- window splits
            actions = {
                open_file = {
                    window_picker = {
                        enable = false,
                    },
                },
            },
            filters = {
                custom = { ".DS_Store" },
            },
        })
    end,
}
