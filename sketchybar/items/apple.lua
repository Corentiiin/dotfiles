local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Padding item required because of bracket
sbar.add("item", { width = 5 })

local apple = sbar.add("item", {
  icon = {
    font = {
       family = settings.font.text,
       style = settings.font.style_map["Heavy"],
       size = 16.0 
      },
    string = icons.apple,
    padding_right = 0,
    padding_left = 8,
    color = colors.white,
  },
  label = { drawing = true },
  -- background = {
  --  color = colors.bg2,
  --  border_color = colors.black,
  --  border_width = 1,
  --  corner_radius = 12,
  -- },
  padding_left = 5,
  padding_right = 0,
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0"
})

-- Double border for apple using a single item bracket
-- sbar.add("bracket", { apple.name }, {
  -- background = {
  --   color = colors.transparent,
  --   height = 30,
  --   border_color = colors.grey,
  -- }
-- })

-- Padding item required because of bracket
sbar.add("item", { width = 7 })
