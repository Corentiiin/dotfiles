local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

--- Battery widget for SketchyBar
-- This widget displays the battery status with an icon and label,
-- and provides a popup with detailed information when clicked.

-- Define the width of the popup
local battery = sbar.add("item", "widgets.battery", {
  position = "right",
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 11.5,
    }
  },
  label = { font = { family = settings.font.numbers, size = 16 }},
  update_freq = 160,
  popup = { align = "center", width = "fit" }
})

-- Titre principal
local battery_popup_title = sbar.add("item", {
  position = "popup." .. battery.name,
  label = {
    string = "Battery",
    font = { family = settings.font.text, style = settings.font.style_map["Bold"], size = 14 },
    align = "left",
    color = colors.white,
  },
  drawing = true,
  y_offset = 10, -- Décale légèrement vers le bas
})

-- Source d'alimentation
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

-- Séparateur
local battery_popup_separator = sbar.add("item", {
  position = "popup." .. battery.name,
  background = {
    height = 1,
    color = colors.popup.border or "#CCCCCC", -- Assure une couleur visible
    corner_radius = 1,
    drawing = true,
    border_width = 1,
  },
  label = { drawing = false },
  icon = { drawing = false },
  drawing = true,
  y_offset = -10, -- Rapproche du texte précédent
})

-- Titre pour le temps restant
local battery_popup_time_title = sbar.add("item", {
  position = "popup." .. battery.name,
  label = {
    string = "Time remaining",
    font = { family = settings.font.text, style = settings.font.style_map["Heavy"], size = 13 },
    align = "left",
    color = colors.lightgrey,
  },
  drawing = true,
  y_offset = -10, -- Rapproche du séparateur
})

-- Ligne avec l'icône et le temps restant
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

battery:subscribe("mouse.clicked", function(env)
  local drawing = battery:query().popup.drawing
  battery:set( { popup = { drawing = "toggle" } })

  if drawing == "off" then
    sbar.exec("pmset -g batt", function(batt_info)
      local found, _, remaining = batt_info:find(" (%d+:%d+) remaining")
      local label = found and remaining .. "h" or "No estimate"
      battery_popup_time_row:set({ label = { string = label } })

      -- Update power source in popup on click as well
      local power_source = batt_info:match("Now drawing from '(.-)'") or batt_info:match("AC Power") and "AC Power" or "Battery"
      battery_popup_power:set({ label = { string = "Power Source: " .. power_source } })
    end)
  end
end)

sbar.add("bracket", "widgets.battery.bracket", { battery.name }, {
  background = { color = colors.transparent }
})

sbar.add("item", "widgets.battery.padding", {
  position = "right",
  width = settings.group_paddings
})
