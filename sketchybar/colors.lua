return {
  white = 0xffe2e2e3,
  red = 0xfffc5d7c,
  blue = 0xff2b86ff, -- lighter, more vibrant blue (#2B86FF)
  grey = 0xff7f8490,
  transparent = 0x00000000,

  popup = {
    bg = 0xc025262a, -- légèrement plus foncé que 0xc02c2e34
    border = 0xff636366, -- gris clair macOS (~60%)
  },

  bg1 = 0xff363944,
  bg2 = 0xff414550,
  selected_bg = 0x44000000, -- semi-transparent dark for selected items (dark frost)

  -- Liquid glass: frosted-glass palette for the bar pills
  liquid_glass = {
    tint   = 0x11222830, -- very subtle dark tint
    border = 0x332c3034, -- darker subtle border
    clear  = 0x00000000, -- fully transparent

    fg = 0xffffffff, -- primary text color: white

    selected = {
      bg = 0x80ffffff, -- blanc clair à 50% transparent
    },
  },

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
