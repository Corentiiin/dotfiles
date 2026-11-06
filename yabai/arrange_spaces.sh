#!/usr/bin/env sh
# With a second display: spaces 1-8 on the main display, 9 and 10 on the
# second one (alt-9 / alt-0). Run at startup and whenever a display is added.
# Needs the scripting addition to create and move spaces.

[ "$(yabai -m query --displays | jq length)" -ge 2 ] || exit 0

# Spaces created on the main display while it was alone (9, 10) move over to
# the second one, highest first so the remaining indexes don't shift
for space in $(yabai -m query --spaces --display 1 | jq '.[8:][].index' | sort -rn); do
    yabai -m space "$space" --display 2
done

# The display may come back with a fresh space of its own on top of those:
# drop empty spaces beyond the second
for space in $(yabai -m query --spaces --display 2 | jq '.[2:][] | select(.windows == []) | .index' | sort -rn); do
    yabai -m space "$space" --destroy
done

count=$(yabai -m query --spaces --display 2 | jq length)
while [ "$count" -lt 2 ]; do
    yabai -m space --create 2 || break
    count=$((count + 1))
done
