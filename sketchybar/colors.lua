-- Apple system colors (macOS dark appearance, the bar sits on the wallpaper)
-- https://developer.apple.com/design/human-interface-guidelines/color
return {
  -- Labels: one white, four levels of emphasis
  label            = 0xffffffff,
  secondary_label  = 0x99ebebf5, -- 60 %
  tertiary_label   = 0x4debebf5, -- 30 %
  quaternary_label = 0x2eebebf5, -- 18 %

  -- System tints
  blue   = 0xff0a84ff,
  green  = 0xff30d158,
  red    = 0xffff453a,
  orange = 0xffff9f0a,
  yellow = 0xffffd60a,

  transparent = 0x00000000,

  -- Recessed track behind the spaces segmented control
  track = {
    fill   = 0x47000000,
    border = 0x1fffffff, -- hairline
  },

  -- Spaces segmented control
  segment = {
    selected     = 0x3dffffff, -- raised selected segment
    selected_rim = 0x33ffffff,
    hover        = 0x17ffffff,
  },

  -- Menu bar item highlight (hover / open popup), like macOS 26
  highlight = 0x26ffffff,

  -- Menus and popups, macOS 26 Control Center style; picked from the system
  -- appearance each time a menu opens
  menu = {
    light = {
      bg           = 0xf0f6f6f6,
      border       = 0x1f000000,
      label        = 0xff1d1d1f,
      secondary    = 0x993c3c43,
      separator    = 0x1a000000,
      hover        = 0x12000000,
      circle       = 0x14000000,
      circle_hover = 0x24000000,
      track        = 0x1f000000,
      accent       = 0xff007aff, -- systemBlue, light appearance
    },
    dark = {
      bg           = 0xe62a2a2c,
      border       = 0x33ffffff,
      label        = 0xfff5f5f7,
      secondary    = 0x99ebebf5,
      separator    = 0x24ffffff,
      hover        = 0x1fffffff,
      circle       = 0x29ffffff,
      circle_hover = 0x3dffffff,
      track        = 0x33ffffff,
      accent       = 0xff0a84ff, -- systemBlue, dark appearance
    },
  },

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
