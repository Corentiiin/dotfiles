-- Only one config may run, and it must be the newest. Subscribing points an
-- item's events at the Lua process that subscribed last, and a reload doesn't
-- stop the previous config: if it was still starting (reloads in a row, a slow
-- wake) it could subscribe after this one and take every event, then die,
-- leaving a bar that never updates (no battery, frozen clock). End older
-- instances before this one sends anything, and only older ones (lower pid):
-- an older config that is slow to start must not kill a newer one. An older
-- config may also have built its items after the reload: remove them, or this
-- config's own items would fail to add as duplicates. In this shell $PPID is
-- this Lua process, and its parent is sketchybar.
os.execute("for pid in $(pgrep -x -P $(ps -o ppid= -p $PPID) lua); do [ $pid -lt $PPID ] && kill -9 $pid; done; "
  .. "sketchybar --remove '/.*/' >/dev/null 2>&1")

-- Require the sketchybar module
sbar = require("sketchybar")

-- Set the bar name, if you are using another bar instance than sketchybar
-- sbar.set_bar_name("bottom_bar")

-- Bundle the entire initial configuration into a single message to sketchybar
sbar.begin_config()
require("bar")
require("default")
require("items")
sbar.end_config()

-- Event provider for clock_tick / battery_change (see helpers/bar_events);
-- restarted on every config load so a reload never leaves two instances
-- No `exec`: the shell must stay alive holding sbar.exec's output pipe; once
-- that pipe closes, SbarLua treats the command as finished and the helper gets
-- killed. Its stderr (failure reasons) lands in the sketchybar error log.
sbar.exec("pkill -x bar_events; $CONFIG_DIR/helpers/bar_events/bin/bar_events >/dev/null")

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
sbar.event_loop()
