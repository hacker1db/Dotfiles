return {
    "eldritch-theme/eldritch.nvim",
    name = "eldritch",
    lazy = false,
    priority = 1000,

    config = function()
        local c = require("core.colors").colors

        require("eldritch").setup({
            transparent = true,
            terminal_colors = true,
            styles = {
                comments = { italic = true },
                keywords = { italic = true },
                functions = { bold = true },
                variables = {},
                sidebars = "dark",
                floats = "dark",
            },
            sidebars = { "qf", "help" },
            hide_inactive_statusline = false,
            dim_inactive = false,
            lualine_bold = true,

            on_highlights = function(hl, _)
                -- Heading backgrounds (from shared palette)
                for i, pair in ipairs({
                    { "linkarzu_color04", "linkarzu_color18" },
                    { "linkarzu_color02", "linkarzu_color19" },
                    { "linkarzu_color03", "linkarzu_color20" },
                    { "linkarzu_color01", "linkarzu_color21" },
                    { "linkarzu_color05", "linkarzu_color22" },
                    { "linkarzu_color08", "linkarzu_color23" },
                }) do
                    local fg = c[pair[1]]
                    local bg = c[pair[2]]
                    hl["Headline" .. i .. "Bg"] = { fg = fg, bg = bg }
                    hl["Headline" .. i .. "Fg"] = { fg = fg, bold = true }
                    hl["@markup.heading." .. i .. ".markdown"] = { fg = fg, bg = bg, bold = true }
                end

                -- Render-markdown
                hl.RenderMarkdownCode = { bg = c["linkarzu_color07"] }
                hl.RenderMarkdownCodeInline = { fg = c["linkarzu_color10"], bg = c["linkarzu_color02"] }
                hl.RenderMarkdownQuote = { fg = c["linkarzu_color12"] }

                -- Markup
                hl["@markup.strong"] = { fg = c["linkarzu_color24"], bold = true }
                hl["@markup.raw.markdown_inline"] = { fg = c["linkarzu_color01"] }

                -- Diagnostics
                hl.DiagnosticError = { fg = c["linkarzu_color11"] }
                hl.DiagnosticWarn = { fg = c["linkarzu_color12"] }
                hl.DiagnosticInfo = { fg = c["linkarzu_color03"] }
                hl.DiagnosticHint = { fg = c["linkarzu_color02"] }
                hl.DiagnosticOk = { fg = c["linkarzu_color04"] }
                hl.DiagnosticUnderlineError = { sp = c["linkarzu_color11"], undercurl = true }
                hl.DiagnosticUnderlineWarn = { sp = c["linkarzu_color12"], undercurl = true }
                hl.DiagnosticUnderlineInfo = { sp = c["linkarzu_color03"], undercurl = true }
                hl.DiagnosticUnderlineHint = { sp = c["linkarzu_color02"], undercurl = true }
                hl.DiagnosticUnderlineOk = { sp = c["linkarzu_color04"], undercurl = true }

                -- Spell
                hl.SpellBad = { sp = c["linkarzu_color11"], undercurl = true, bold = true, italic = true }
                hl.SpellCap = { sp = c["linkarzu_color12"], undercurl = true, bold = true, italic = true }
                hl.SpellLocal = { sp = c["linkarzu_color12"], undercurl = true, bold = true, italic = true }
                hl.SpellRare = { sp = c["linkarzu_color04"], undercurl = true, bold = true, italic = true }

                -- Transparent folded lines
                hl.Folded = { bg = "NONE" }
            end,
        })
        vim.cmd.colorscheme("eldritch")

        -- Apply additional highlights after colorscheme loads
        require("core.highlights")
    end,
}
