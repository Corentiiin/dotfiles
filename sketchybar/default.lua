local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
sbar.default({
  -- Not "when_shown": the bar isn't shown behind a fullscreen app or the lock
  -- screen, and items would miss their events there (clock, battery, Wi-Fi),
  -- coming back stale. Events are rare, so handling them unseen costs nothing.
  updates = true,
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Medium"],
      size = 13.0
    },
    color = colors.label,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Regular"],
      size = 15.0
    },
    color = colors.label,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  background = {
    height = 24,
    corner_radius = 12,
    border_width = 0,
    padding_left = settings.group_paddings,
    padding_right = settings.group_paddings,
  },
  -- macOS 26 menus: blurred material, large radius, hairline border
  popup = {
    background = {
      border_width = 1,
      corner_radius = 14,
      border_color = colors.menu.light.border,
      color = colors.menu.light.bg,
      shadow = { drawing = true, color = 0x29000000, angle = 90, distance = 3 },
    },
    blur_radius = 50,
    y_offset = 4,
  },
  padding_left = 5,
  padding_right = 5,
  -- Scrolling a text that overflows runs an animation on every frame
  scroll_texts = false,
})
