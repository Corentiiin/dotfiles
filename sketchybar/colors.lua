return {
  black = 0xff181819,
  white = 0xffe2e2e3,
  red = 0xfffc5d7c,
  green = 0xff9ed072,
  blue = 0xff76cce0,
  yellow = 0xffe7c664,
  orange = 0xfff39660,
  magenta = 0xffb39df3,
  grey = 0xff7f8490,
  lightgrey = 0xffb0b0b8,
  transparent = 0x00000000,

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
  selected_bg = 0xcc3a4256,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
