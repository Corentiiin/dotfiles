-- Battery widget for SketchyBar
-- This widget displays the battery status with an icon and label

local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Create a battery widget for SketchyBar
local battery = sbar.add("item", "widgets.battery", {
  position = "right",
  -- Percentage number
  icon = {
    font = {
      size = 11.5,
    },
    padding_left = 6
  },
  -- Icon for the battery widget
  label = { 
    font = { 
      size = 17 
    },
    padding_right = 6
  },

  update_freq = 120,
  popup = { align = "right", width = "fit" }
})

-- Subscribe to battery updates
battery:subscribe({"routine", "power_source_change", "system_woke"}, function()
  sbar.exec("pmset -g batt", function(batt_info)
    local icon = "!"
    local label = "?"

    local found, _, charge = batt_info:find("(%d+)%%")
    if found then
      charge = tonumber(charge)
      label = charge .. " %"
    end

    local charging, _, _ = batt_info:find("AC Power")

    if charging then
      icon = icons.battery.charging
    else
      if found and charge > 80 then
        icon = icons.battery._100
      elseif found and charge > 60 then
        icon = icons.battery._75
      elseif found and charge > 40 then
        icon = icons.battery._50
      elseif found and charge > 20 then
        icon = icons.battery._25
      else
        icon = icons.battery._0
      end
    end

    local lead = ""
    if found and charge < 10 then
      lead = "0"
    end

    battery:set({
      label = {
        string = icon
      },
      icon = { string = lead .. label },
    })
  end)
end)

