-- Item to display the current date and time in a calendar forma

local settings = require("settings")
local colors = require("colors")

local calendar = sbar.add("item", {
  position = "right",
  -- Day, Month, Date 
  icon = {
    padding_left = 6,
    padding_right = 8,
    font = {
      size = 13,
    },
  },  
  -- Time in HH:MM format
  label = {
    padding_right = 12,
    font = { 
      family = settings.font.text, 
      style = settings.font.style_map["Semibold"], 
      size = 13
    },
  },
  update_freq = 60,
  click_script = "open -a 'Calendar'"
})

calendar:subscribe({ "forced", "routine", "system_woke" }, function(env)
  local day = os.date("%d") -- Get the day of the month
  day = tostring(tonumber(day)) -- Convert to number to remove leading zero

  calendar:set({ icon = os.date("%a %b ") .. day, label = os.date("%H:%M") })
end)
