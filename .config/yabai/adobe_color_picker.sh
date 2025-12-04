#!/bin/bash

while true; do
  result=$(osascript <<EOF
tell application "System Events"
    if exists (process "Adobe Photoshop 2025") then
        set winlist to name of windows of process "Adobe Photoshop 2025"
        repeat with winName in winlist
            if winName contains "カラーピッカー" then
                return "FOUND"
            end if
        end repeat
    end if
end tell
return "NOTFOUND"
EOF
)

  if [ "$result" == "FOUND" ]; then
    # カラーピッカーが出ているなら yabai で float を試みる
    ids=$(yabai -m query --windows --space all 2>/dev/null | jq -r '.[] | select(.app | test("^Adobe Photoshop")) | select(.title | test("カラーピッカー")) | .id')
    for id in $ids; do
      yabai -m window --id "$id" --set float true
    done
  fi

  sleep 0.5
done

