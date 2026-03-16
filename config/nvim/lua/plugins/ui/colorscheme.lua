return {
    "eldritch-theme/eldritch.nvim",
    name = "eldritch",
    lazy = false,
    priority = 1000,

    config = function()
        require("eldritch").setup({
            transparent = true, -- Enable this to disable setting the background color
            terminal_colors = true, -- Configure the colors used when opening a `:terminal` in Neovim
            styles = {
                -- Style to be applied to different syntax groups
                -- Value is any valid attr-list value for `:help nvim_set_hl`
                comments = { italic = true },
                keywords = { italic = true },
                functions = { bold = true },
                variables = {},
                -- Background styles. Can be "dark", "transparent" or "normal"
                sidebars = "dark", -- style for sidebars, see below
                floats = "dark", -- style for floating windows
            },
            sidebars = { "qf", "help" }, -- Set a darker background on sidebar-like windows
            hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead
            dim_inactive = false, -- dims inactive windows, transparent must be false for this to work
            lualine_bold = true, -- When `true`, section headers in the lualine theme will be bold

            -- linkarzu-style markdown heading + render-markdown highlights (transparent mode)
            on_highlights = function(hl, _)
                -- Heading backgrounds (colored fg + dark tinted bg)
                hl.Headline1Bg = { fg = "#987afb", bg = "#2d244b" }
                hl.Headline2Bg = { fg = "#37f499", bg = "#10492d" }
                hl.Headline3Bg = { fg = "#04d1f9", bg = "#013e4a" }
                hl.Headline4Bg = { fg = "#fca6ff", bg = "#4b314c" }
                hl.Headline5Bg = { fg = "#9ad900", bg = "#1e2b00" }
                hl.Headline6Bg = { fg = "#e58f2a", bg = "#2d1c08" }

                -- Heading foreground-only (for sign column / icons)
                hl.Headline1Fg = { fg = "#987afb", bold = true }
                hl.Headline2Fg = { fg = "#37f499", bold = true }
                hl.Headline3Fg = { fg = "#04d1f9", bold = true }
                hl.Headline4Fg = { fg = "#fca6ff", bold = true }
                hl.Headline5Fg = { fg = "#9ad900", bold = true }
                hl.Headline6Fg = { fg = "#e58f2a", bold = true }

                -- render-markdown code / inline code / quote
                hl.RenderMarkdownCode = { bg = "#141b22" }
                hl.RenderMarkdownCodeInline = { fg = "#0D1116", bg = "#37f499" }
                hl.RenderMarkdownQuote = { fg = "#f1fc79" }

                -- Treesitter markup overrides
                hl["@markup.heading.1.markdown"] = { fg = "#987afb", bg = "#2d244b", bold = true }
                hl["@markup.heading.2.markdown"] = { fg = "#37f499", bg = "#10492d", bold = true }
                hl["@markup.heading.3.markdown"] = { fg = "#04d1f9", bg = "#013e4a", bold = true }
                hl["@markup.heading.4.markdown"] = { fg = "#fca6ff", bg = "#4b314c", bold = true }
                hl["@markup.heading.5.markdown"] = { fg = "#9ad900", bg = "#1e2b00", bold = true }
                hl["@markup.heading.6.markdown"] = { fg = "#e58f2a", bg = "#2d1c08", bold = true }
                hl["@markup.strong"] = { fg = "#f94dff", bold = true }
                hl["@markup.raw.markdown_inline"] = { fg = "#fca6ff" }

                -- Transparent folded lines
                hl.Folded = { bg = "NONE" }
            end,
        })
        -- setup must be called before loading
        vim.cmd.colorscheme("eldritch")
    end,
}
