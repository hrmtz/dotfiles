local wezterm = require 'wezterm'

local config = {}

-- 既存設定
config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.use_ime = true
config.font_size = 14.0

-----------------------------------------------------
-- ■ 1. Quake コンソール設定（最重要）
-----------------------------------------------------

-- Quake 用にウィンドウ位置とサイズを制御する
wezterm.on("gui-startup", function(cmd)
  -- Quake ウィンドウを1つだけ作る
  local args = cmd.args or {}
  wezterm.mux.spawn_window{
    args = args,
    workspace = "default",
    position = { x = 0, y = 0 },
    size = { width = wezterm.gui.screens().active.width, height = math.floor(wezterm.gui.screens().active.height * 0.35) },
    class = "WezTermQuake",
  }
end)

-- Quake 用ウィンドウにタイトルを付ける
config.window_class = "WezTerm"
config.window_background_opacity = 0.95

-----------------------------------------------------
-- ■ 2. Quake 呼び出し用トグルのキーバインド
-- skhd から “呼び出すだけ” で toggle が成立する
-----------------------------------------------------
config.keys = {
  -- F12 や Ctrl+` にしてもいい
  {
    key = "F12",
    mods = "CTRL",
    action = wezterm.action.Show,
  },
}

return config
