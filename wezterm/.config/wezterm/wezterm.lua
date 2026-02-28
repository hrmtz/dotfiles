local wezterm = require 'wezterm'

local config = {}

config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.use_ime = true
config.unicode_version = 14
config.font_size = 14.0
config.window_background_opacity = 1.0
config.color_scheme = "Tokyo Night"
config.bold_brightens_ansi_colors = true
config.colors = {
    brights = {
        "#666688",  -- bright black (dim text) → 明るいグレーに
        "#f7768e",  -- bright red
        "#9ece6a",  -- bright green
        "#e0af68",  -- bright yellow
        "#7dcfff",  -- bright blue → 明るい水色に
        "#bb9af7",  -- bright magenta
        "#7dcfff",  -- bright cyan
        "#c0caf5",  -- bright white
    },
}

return config
