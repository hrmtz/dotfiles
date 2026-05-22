local wezterm = require 'wezterm'

local config = {}

config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.use_ime = true
config.unicode_version = 14
config.font = wezterm.font_with_fallback({
    "HackGen35 Console NF",
    "Hiragino Sans",
    "Apple Color Emoji",
})
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

-- スリープ復帰時のマウスモードリセット（Ctrl+Shift+R）
config.keys = {
    {
        key = 'r',
        mods = 'CTRL|SHIFT',
        action = wezterm.action.SendString(
            '\x1b[?1006l\x1b[?1003l\x1b[?1002l\x1b[?1000l'
        ),
    },
    -- cmd-q を無効化（cmd-w との誤爆防止）
    {
        key = 'q',
        mods = 'CMD',
        action = wezterm.action.DisableDefaultAssignment,
    },
}

return config
