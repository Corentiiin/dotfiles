local icons    = require("icons")
local colors   = require("colors")
local settings = require("settings")
local hover    = require("helpers.hover")

-- The percentage goes in `icon` and the glyph in `label` on purpose:
-- sketchybar always draws icon before label, and macOS shows "36 %" then the battery.
local battery = sbar.add("item", "widgets.battery", {
  position      = "right",
  padding_left  = 2,
  padding_right = 2,
  icon = {
    font = {
      family = settings.font.text,
      style  = settings.font.style_map["Semibold"],
      size   = 12.0,
    },
    padding_left  = 10,
    padding_right = 5,
  },
  label = {
    font = {
      family = settings.font.text,
      style  = settings.font.style_map["Regular"],
      size   = 17.0,
    },
    padding_left  = 0,
    padding_right = 10,
  },
  background  = { drawing = true, color = colors.transparent },
  update_freq = 60,
  click_script = "open 'x-apple.systempreferences:com.apple.Battery-Settings.extension'",
})

hover(battery)

local function icon_for_charge(charge)
  if     charge > 80 then return icons.battery._100
  elseif charge > 60 then return icons.battery._75
  elseif charge > 40 then return icons.battery._50
  elseif charge > 20 then return icons.battery._25
  else                    return icons.battery._0
  end
end

battery:subscribe({ "routine", "forced", "power_source_change", "system_woke" }, function()
  sbar.exec("pmset -g batt", function(batt_info)
    local found, _, charge = batt_info:find("(%d+)%%")
    charge = found and tonumber(charge) or nil

    -- "AC Power" alone also covers "charged" / "not charging": only show the bolt
    -- while the battery is actually filling up
    local charging = batt_info:find("; charging;") or batt_info:find("finishing charge")

    local icon
    if charging then   icon = icons.battery.charging
    elseif charge then icon = icon_for_charge(charge)
    else               icon = icons.battery._0
    end

    -- Like macOS: the battery turns red when low, green while charging
    local glyph_color = colors.label
    if charging then
      glyph_color = colors.green
    elseif charge and charge <= 20 then
      glyph_color = colors.red
    end

    battery:set({
      icon  = { string = charge and (charge .. " %") or "–" },
      label = { string = icon, color = glyph_color },
    })
  end)
end)
