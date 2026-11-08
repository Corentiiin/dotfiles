#!/usr/bin/env sh
# alt-<n>: focuses space $1. Pressing the number of the space already focused
# returns to the previous one; a missing space (e.g. 10) does nothing.
# When the space is on another display than the mouse, the mouse follows it
# (to the focused window, else the middle of the display); a switch within
# the display under the mouse leaves it alone.

# One query gives the focused space, the target's display and the number of
# displays: "<focused> <target display or 0> <displays>"
set -- "$1" $(yabai -m query --spaces | jq -r --argjson t "$1" '
    "\(map(select(."has-focus"))[0].index // 0) \(map(select(.index == $t))[0].display // 0) \(map(.display) | unique | length)"')
target=$1 focused=$2 display=$3 displays=$4

if [ "$focused" = "$target" ]; then
    set -- $(yabai -m query --spaces --space recent 2>/dev/null | jq -r '"\(.index) \(.display)"')
    target=$1 display=$2
fi
[ -n "$target" ] && [ "$display" != 0 ] || exit 0

yabai -m space --focus "$target" 2>/dev/null

# A single display: the mouse is always on the right one
[ "$displays" -gt 1 ] || exit 0
[ "$display" = "$(yabai -m query --displays --display mouse | jq .index)" ] && exit 0

# yabai frames are in global coordinates with the origin at the top-left of
# the main display, like the pointer
frame=$(yabai -m query --windows --window 2>/dev/null | jq -c "select(.space == $target) | .frame")
[ -n "$frame" ] || frame=$(yabai -m query --displays --display "$display" | jq -c .frame)
"$(dirname "$0")/helpers/bin/warp_mouse" $(echo "$frame" | jq -r '"\(.x + .w / 2) \(.y + .h / 2)"')
