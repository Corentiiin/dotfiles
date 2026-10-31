local colors = require("colors")

-- Equivalent to the --bar domain
-- Fully transparent like the macOS 26 menu bar: items float on the wallpaper
sbar.bar({
  height = 34,
  color = colors.transparent,
  padding_right = 10,
  padding_left = 10,
})
