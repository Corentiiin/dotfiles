local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local hover = require("helpers.hover")

-- The Apple logo opens the real Apple menu, like the native menu bar
local apple = sbar.add("item", "apple_logo", {
  padding_left  = 0,
  padding_right = 6,
  icon = {
    string = icons.apple,
    font = {
      family = settings.font.text,
      style  = settings.font.style_map["Medium"],
      size   = 16.0,
    },
    color         = colors.label,
    padding_left  = 10,
    padding_right = 10,
    y_offset      = 1,
  },
  label      = { drawing = false },
  background = { drawing = true, color = colors.transparent },
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})

hover(apple)
