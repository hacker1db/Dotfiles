return {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
        heading = {
            enabled = true,
            sign = false,
            icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
            backgrounds = {
                "Headline1Bg",
                "Headline2Bg",
                "Headline3Bg",
                "Headline4Bg",
                "Headline5Bg",
                "Headline6Bg",
            },
            foregrounds = {
                "Headline1Fg",
                "Headline2Fg",
                "Headline3Fg",
                "Headline4Fg",
                "Headline5Fg",
                "Headline6Fg",
            },
        },
        checkbox = {
            enabled = true,
            right_pad = 1,
            unchecked = { icon = "󰄱 " },
            checked = { icon = "󰄵 " },
            custom = {
                todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
            },
        },
        bullet = {
            enabled = true,
            right_pad = 1,
            icons = { "●", "○", "◆", "◇" },
        },
        code = {
            enabled = true,
            sign = true,
            style = "full",
            left_pad = 1,
            right_pad = 1,
            border = "thin",
        },
        pipe_table = {
            enabled = true,
            style = "full",
        },
        link = {
            enabled = true,
            hyperlink = "󰌷 ",
            wiki = { icon = "󱗖 " },
        },
    },
}
