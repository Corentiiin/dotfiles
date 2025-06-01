-- Battery widget for SketchyBar
-- This widget displays the battery status with an icon and label,
-- and provides a popup with detailed information when clicked.

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

-- Title for the battery widget
local battery_popup_title = sbar.add("item", {
  position = "popup." .. battery.name,
  label = {
    string = "Battery",
    font = { family = settings.font.text, style = settings.font.style_map["Bold"], size = 14 },
    align = "left",
    color = colors.white,
  },
  drawing = true,
  align = "right",
})

-- Power source row
local battery_popup_power = sbar.add("item", {
  position = "popup." .. battery.name,
  label = {
    string = "Power Source: ...",
    font = { family = settings.font.text, style = settings.font.style_map["Semibold"], size = 12 },
    align = "left",
    color = colors.grey,
  },
  drawing = true,
  y_offset = -5, -- Rapproche du titre
})

-- Separator for the popup
local battery_popup_separator = sbar.add("item", {
  position = "popup." .. battery.name,
  background = {
    height = 1,
    color = colors.popup.border or "#CCCCCC",
    corner_radius = 1,
    drawing = true,
    border_width = 1,
  },
  label = { drawing = false },
  icon = { drawing = false },
  drawing = true,
  y_offset = -10,
})

-- Title for time remaining
local battery_popup_time_title = sbar.add("item", {
  position = "popup." .. battery.name,
  label = {
    string = "Time remaining",
    font = { family = settings.font.text, style = settings.font.style_map["Heavy"], size = 13 },
    align = "left",
    color = colors.lightgrey,
  },
  drawing = true,
  y_offset = -10,
})

-- Time remaining row
local battery_popup_time_row = sbar.add("item", {
  position = "popup." .. battery.name,
  icon = {
    string = icons.battery.remaining_time,
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 12,
    },
  },
  label = {
    string = "??:?? heures",
    align = "left",
    font = { family = settings.font.text, style = settings.font.style_map["Semibold"], size = 12 },
    color = colors.white,
  },
  drawing = true,
  background = {
    border_width = 1,
    border_color = colors.purple or "#8000FF",
    corner_radius = 2,
    drawing = true,
    y_offset = -2,
  },
  y_offset = -10, -- Rapproche du titre précédent
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

    -- Update power source in popup
    local power_source = batt_info:match("Now drawing from '(.-)'") or batt_info:match("AC Power") and "AC Power" or "Battery"
    battery_popup_power:set({ label = { string = "Power Source: " .. power_source } })
  end)
end)

-- Subscribe to mouse click events to toggle the popup
battery:subscribe("mouse.clicked", function(env)
  local drawing = battery:query().popup.drawing
  battery:set({ popup = { drawing = "toggle" } })

  if drawing == "off" then
    sbar.exec("pmset -g batt", function(batt_info)
      local found, _, remaining = batt_info:find(" (%d+:%d+) remaining")
      local label = found and remaining .. "h" or "No estimate"
      battery_popup_time_row:set({ label = { string = label } })

      local power_source = batt_info:match("Now drawing from '(.-)'") or batt_info:match("AC Power") and "AC Power" or "Battery"
      battery_popup_power:set({ label = { string = "Power Source: " .. power_source } })
    end)

    -- Set background to light grey transparent when popup is displayed
    battery:set({ background = { color = colors.selected_bg } })
  else
    -- Remove background when popup is hidden
    battery:set({ background = { color = colors.transparent } })
  end
end)

battery:subscribe("mouse.exited.global", function()
  battery:set({ popup = { drawing = false } })
  battery:set({ background = { color = colors.transparent } })
end)

