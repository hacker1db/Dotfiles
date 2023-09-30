local wezterm = require("wezterm")

local config = {
    -- window_background_opacity = 0.15,
    macos_window_background_blur = 30,
    enable_tab_bar = false,
    window_decorations = "RESIZE",
    font = wezterm.font("CaskaydiaCove Nerd Font", { weight = "Regular" }),
    font_size = 14,
    adjust_window_size_when_changing_font_size = true,
    native_macos_fullscreen_mode = true,
    keys = {
        {
            key = "n",
            mods = "SHIFT|CTRL",
            action = wezterm.action.ToggleFullScreen,
        },
    },
    window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    },
    send_composed_key_when_left_alt_is_pressed = true,
    send_composed_key_when_right_alt_is_pressed = false,
}

config.color_scheme = "Dracula"
config.window_frame = {
    -- The font used in the tab bar.
    -- Roboto Bold is the default; this font is bundled
    -- with wezterm.
    -- Whatever font is selected here, it will have the
    -- main font setting appended to it to pick up any
    -- fallback fonts you may have used there.
    font = wezterm.font({ family = "Roboto", weight = "Bold" }),

    -- The size of the font in the tab bar.
    -- Default to 10.0 on Windows but 12.0 on other systems
    font_size = 12.0,

    -- The overall background color of the tab bar when
    -- the window is focused
    active_titlebar_bg = "#333333",

    -- The overall background color of the tab bar when
    -- the window is not focused
    inactive_titlebar_bg = "#333333",
}

config.colors = {
    tab_bar = {
        -- The color of the inactive tab bar edge/divider
        inactive_tab_edge = "#575757",
    },
}

return config
