local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local cal = sbar.add("item", {
  icon = {
    color = colors.white,
    padding_left = 6,
    padding_right = 8,
    font = {
      style = settings.font.style_map["SemiBold"],
      family = settings.font.text,
      size = 13.0,
    },
  },  
  label = {
    color = colors.white,
    padding_right = 11,
    width = 49,
    align = "right",
    font = { family = settings.font.text, style = settings.font.style_map["SemiBold"], size = 13.0 },
  },
  position = "right",
  update_freq = 30,
  padding_left = 4,
  padding_right = 5,
  background = {
    color = colors.transparent,
    border_color = colors.transparent,
    border_width = 0
  },
  click_script = "open -a 'Calendar'"
})

-- Double border for calendar using a single item bracket
sbar.add("bracket", { cal.name }, {
  background = {
    color = colors.transparent,
    height = 30,
    border_color = colors.grey,
  }
})

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
  cal:set({ icon = os.date("%a %b %d"), label = os.date("%H:%M") })
end)
