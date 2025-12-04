#!/bin/bash

# 状態を記録する一時ファイル
STATE_FILE="/tmp/yabai_photoshop_picker_state"

# 現在 picker が開いているかを判定
is_picker_open() {
    yabai -m query --windows |
        jq -r '.[] | select(.app | test("Adobe Photoshop")) | select(.title | test("カラーピッカー"))' |
        grep -q カラーピッカー
}

# 現在の yabai 状態（停止中かどうか）
is_yabai_stopped() {
    brew services list | grep -E '^yabai' | grep -q 'stopped'
}

# メインループ（5秒ごとにチェック）
while true; do
    if is_picker_open; then
        if ! is_yabai_stopped; then
            echo "🟥 カラーピッカー検出 → yabai停止"
            yabai --stop-service
            echo "stopped" > "$STATE_FILE"
        fi
    else
        if is_yabai_stopped && [[ -f "$STATE_FILE" ]]; then
            echo "🟩 カラーピッカー終了 → yabai再開"
            yabai --start-service
            rm "$STATE_FILE"
        fi
    fi
    sleep 5
done

