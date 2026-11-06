#!/usr/bin/env sh
# alt-<n>: focuses space $1. Pressing the number of the space already focused
# returns to the previous one; a missing space (e.g. 10) does nothing.
# When the space is on another display than the mouse, the mouse follows it
# (to the focused window, else the middle of the display); a switch within
# the display under the mouse leaves it alone.

target=$1
[ "$(yabai -m query --spaces --space | jq .index)" = "$target" ] && target=recent
set -- $(yabai -m query --spaces --space "$target" 2>/dev/null | jq -r '"\(.index) \(.display)"')
[ $# -eq 2 ] || exit 0
space=$1 display=$2

yabai -m space --focus "$space" 2>/dev/null

[ "$display" = "$(yabai -m query --displays --display mouse | jq .index)" ] && exit 0

# yabai frames are in global coordinates with the origin at the top-left of
# the main display, like the pointer
frame=$(yabai -m query --windows --window 2>/dev/null | jq -c "select(.space == $space) | .frame")
[ -n "$frame" ] || frame=$(yabai -m query --displays --display "$display" | jq -c .frame)
"$(dirname "$0")/helpers/bin/warp_mouse" $(echo "$frame" | jq -r '"\(.x + .w / 2) \(.y + .h / 2)"')
