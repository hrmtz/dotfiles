-- WezTerm を Quake 風にトグルするシンプル版
-- 依存しているのはごく基本的な API だけ

local hotkey_mods = { "cmd", "shift" }
local hotkey_key  = "space"


local wezterm_app_name = "WezTerm"
local wezterm_app_path = "/Applications/WezTerm.app" -- 場所が違うならここだけ直す

local function toggle_wezterm_quake()
  local frontApp = hs.application.frontmostApplication()

  -- すでに WezTerm が前面に出ていれば → 隠す
  if frontApp and frontApp:name() == wezterm_app_name then
    frontApp:hide()
    return
  end

  -- WezTerm を前面に出す / 起動する
  hs.application.launchOrFocus(wezterm_app_path)

  -- 少し待ってから「今前面にあるウィンドウ」を調整する
  hs.timer.doAfter(0.3, function()
    local win = hs.window.frontmostWindow()
    if not win then return end

    local app = win:application()
    if not app or app:name() ~= wezterm_app_name then
      -- 前面が別アプリなら何もしない
      return
    end

    

local screen = hs.screen.mainScreen()
local f = screen:frame()

local width_ratio  = 0.60  -- 横幅 60%
local height_ratio = 0.40  -- 高さ 20%（好みで 0.15〜0.25 あたり）

local w = f.w * width_ratio
local h = f.h * height_ratio

local target_frame = {
  -- 横中央に寄せる
  x = f.x + (f.w - w) / 2,
  -- 上端を画面の 40% の位置に
  y = f.y + f.h * 0.20,
  w = w,
  h = h,
}

win:setFrame(target_frame)
win:raise()
win:focus()

    win:raise()
    win:focus()
  end)
end

hs.hotkey.bind(hotkey_mods, hotkey_key, toggle_wezterm_quake)
