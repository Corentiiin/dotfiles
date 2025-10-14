local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local apple = sbar.add("item", "apple_logo", {
  icon = {
    font = {
       family = settings.font.text,
       style = settings.font.style_map["Heavy"],
       size = 16.0
      },
    string = icons.apple,
    color = colors.white,
    padding_left = 0,
    padding_right = 0,
    highlight_color = colors.blue,
  },
  label = { 
    string = "|",
    font = {
       family = settings.font.text,
       style = settings.font.style_map["Regular"],
      },
    drawing = true,
    padding_left = 8,
  },
  background = { 
    drawing = false,
  },
  width = 34,
  padding_left = 10,
  padding_right = 10,
  -- no margin_right here: spacing is handled by the container
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0"
})

-- attach the apple logo item to the container so the container background is the visible box
apple:set({ parent = "apple.container" })
