-- Widgets for SketchyBar
-- This file initializes various widgets for SketchyBar.

require("items.widgets.battery")
require("items.widgets.wifi")
require("items.widgets.volume")

local colors = require("colors")

-- create a bracket that groups wifi, sound and battery widgets (use explicit item names)
local function hex(v) return string.format("0x%08x", v) end
local sys_bracket_cmd = table.concat({
  "sketchybar",
  "--add", "bracket", "sys_status",
    "widgets.wifi.padding",
    "widgets.wifi.bracket",
    "widgets.volume",
    "widgets.volume1",
    "widgets.battery",
  "--set", "sys_status",
    "background.color=" .. hex(colors.with_alpha(colors.liquid_glass.frost, 0.12)),
    "background.corner_radius=12",
    "background.height=30",
    "background.border_width=1",
    "background.border_color=" .. hex(colors.liquid_glass.border),
}, " ")

sbar.exec(sys_bracket_cmd)