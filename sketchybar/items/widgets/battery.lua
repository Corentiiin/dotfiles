local icons    = require("icons")
local colors   = require("colors")
local settings = require("settings")

local battery = sbar.add("item", "widgets.battery", {
  position      = "right",
  padding_right = 10,  -- right margin inside the sys_status bracket (matches spaces outer padding)
  icon = {
    font         = { size = 11.5 },
    padding_left = 0,
  },
  label = {
    font          = { size = 17 },
    padding_right = 4,
  },
  update_freq = 60,
  popup       = { align = "right", width = "fit" },
})

battery:subscribe({ "routine", "forced", "power_source_change", "system_woke" }, function()
  sbar.exec("pmset -g batt", function(batt_info)
    local found, _, charge = batt_info:find("(%d+)%%")
    local charging         = batt_info:find("AC Power")

    charge = found and tonumber(charge) or nil

    local icon
    if charging then
      icon = icons.battery.charging
    elseif charge and charge > 80 then icon = icons.battery._100
    elseif charge and charge > 60 then icon = icons.battery._75
    elseif charge and charge > 40 then icon = icons.battery._50
    elseif charge and charge > 20 then icon = icons.battery._25
    else                                icon = icons.battery._0
    end

    local label = charge and (charge .. " %") or "?"
    -- Pad single-digit percentages so the layout doesn't shift
    local prefix = (charge and charge < 10) and "0" or ""

    -- Turn label red when battery is low and not charging
    local color = (not charging and charge and charge <= 20)
      and colors.red or colors.white

    battery:set({
      label = { string = icon },
      icon  = { string = prefix .. label, color = color },
    })
  end)
end)
