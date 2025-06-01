local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
sbar.default({
  updates = "when_shown",
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Light"],
      size = 13.0
    },
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 14.0
    },
    padding_left = settings.paddings,
    padding_right = settings.paddings,
    background = { image = { corner_radius = 9 } },
  },
  background = {
    height = 28,
    corner_radius = 4,
    border_width = 0,
    padding_left = settings.group_paddings,
    padding_right = settings.group_paddings,
  },
  popup = {
    background = {
      border_width = 1.5,
      corner_radius = 4,
      border_color = colors.popup.border,
      color = colors.popup.bg,
      shadow = { drawing = true },
    },
    blur_radius = 40,
  },
  padding_left = 5,
  padding_right = 5,
  scroll_texts = true,
})
