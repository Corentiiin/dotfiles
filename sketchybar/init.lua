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
-- It also ends any older config instance: one that missed its reload (e.g.
-- the Mac fell asleep mid-reload) otherwise lingers forever. In this shell
-- $PPID is this Lua process, and its parent is sketchybar.
sbar.exec("pkill -x bar_events; "
  .. "for pid in $(pgrep -x -P $(ps -o ppid= -p $PPID) lua); do [ $pid = $PPID ] || kill -9 $pid; done; "
  .. "$CONFIG_DIR/helpers/bar_events/bin/bar_events >/dev/null")

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
sbar.event_loop()
