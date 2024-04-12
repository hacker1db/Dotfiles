local wezterm = require("wezterm")
function scheme_for_appearance(appearance)
    if appearance:find("Dark") then
        return "Catppuccin Mocha"
    else
        return "Catppuccin Latte"
    end
end

local config = {
    window_background_opacity = 0.80,
    macos_window_background_blur = 30,
    enable_tab_bar = false,
    window_decorations = "RESIZE",
    font = wezterm.font("CaskaydiaCove Nerd Font", { weight = "Regular", italic = true }),

    font_size = 16,
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
        top = 20,
        bottom = 0,
    },
    send_composed_key_when_left_alt_is_pressed = true,
    send_composed_key_when_right_alt_is_pressed = false,
    hide_tab_bar_if_only_one_tab = true,
    color_scheme = scheme_for_appearance(wezterm.gui.get_appearance()),
}

return config
