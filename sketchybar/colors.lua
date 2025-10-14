return {
  black = 0xff181819,
  white = 0xffe2e2e3,
  red = 0xfffc5d7c,
  green = 0xff9ed072,
  blue = 0xff2b86ff, -- lighter, more vibrant blue (#2B86FF)
  yellow = 0xffe7c664,
  orange = 0xfff39660,
  magenta = 0xffb39df3,
  grey = 0xff7f8490,
  lightgrey = 0xffb0b0b8,
  transparent = 0x00000000,
  panel_white = 0xeeffffff, -- blanc de panneau très opaque (utile sur fonds lumineux)

  bar = {
    bg = 0xff0a142b,
    border = 0xff2c2e34,
  },
  popup = {
    bg = 0xc025262a, -- légèrement plus foncé que 0xc02c2e34
    border = 0xff636366, -- gris clair macOS (~60%)
  },

  bg1 = 0xff363944,
  bg2 = 0xff414550,
  selected_bg = 0x44000000, -- semi-transparent dark for selected spaces (dark frost)

  -- Liquid glass: multi-layer palette for a more realistic frosted-glass/nav-bar effect
  liquid_glass = {
    base         = 0xff2b86ff, -- use the lighter blue as the liquid-glass base tint
    tint         = 0x11222830, -- very subtle dark tint if needed
    frost        = 0x66000000, -- dark frosted overlay (semi-transparent black)
    inner_shadow = 0x22000000, -- faint inner shadow for depth (~13% black)
    specular     = 0x22ffffff, -- subtle specular (kept low)
    rim          = 0x18ffffff, -- faint rim light (kept low)
    shadow       = 0x22000000, -- soft outer shadow (~13% black)
    border       = 0x332c3034, -- darker subtle border
    clear        = 0x00000000, -- fully transparent

    -- Text / font colors for liquid glass elements (white on dark frost)
    fg           = 0xffffffff, -- primary text color: white
    selected_fg  = 0xffffffff, -- selected text: white

    -- Selected state: composed values to layer for realistic selected appearance
    selected = {
      bg           = 0x80ffffff, -- blanc clair à 50% transparent
      tint         = 0x11000000,
      glow         = 0x22ffffff,
      ring         = 0x221f2226,
      inner_shadow = 0x22000000,
    },
  },

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
