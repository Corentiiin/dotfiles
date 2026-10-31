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
sbar.exec("pkill -x bar_events; $CONFIG_DIR/helpers/bar_events/bin/bar_events >/dev/null 2>&1")

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
sbar.event_loop()
