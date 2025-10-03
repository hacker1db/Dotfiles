return {
    "echasnovski/mini.statusline",
    version = "*",
    enabled = false, -- Set to true if you prefer mini.statusline over lualine
    event = "VeryLazy",
    config = function()
        local statusline = require("mini.statusline")
        statusline.setup({
            -- Content of statusline as functions which return statusline string. See
            -- `:h statusline` and code of default contents (used instead of `nil`).
            content = {
                -- Content for active window
                active = nil,
                -- Content for inactive window(s)
                inactive = nil,
            },

            -- Whether to use icons by default
            use_icons = vim.g.have_nerd_font ~= false,

            -- Whether to set Vim's settings for statusline (make it always shown with
            -- global statusline). NOTE: `content` can still be manually overridden.
            set_vim_settings = true,
        })

        -- You can configure the statusline sections:
        -- Example to show git branch in the statusline
        -- statusline.section_location = function()
        --   return '%2l:%-2v'
        -- end
    end,
}