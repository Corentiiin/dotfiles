-- Widgets for SketchyBar
-- This file initializes various widgets for SketchyBar.

require("items.widgets.battery")
require("items.widgets.wifi")
require("items.widgets.volume")

local colors = require("colors")

-- Group wifi, sound and battery widgets in one frosted-glass pill
sbar.add("bracket", "sys_status", {
  "widgets.wifi.padding",
  "widgets.volume1",
  "widgets.battery",
}, {
  background = {
    color         = colors.with_alpha(colors.liquid_glass.tint, 0.20),
    corner_radius = 15,
    height        = 30,
    border_width  = 1,
    border_color  = colors.liquid_glass.border,
  },
})
