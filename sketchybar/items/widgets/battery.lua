local icons  = require("icons")
local colors = require("colors")

-- The percentage goes in `icon` and the glyph in `label` on purpose:
-- sketchybar always draws icon before label, and the text must come first.
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
})

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
    if charging then       icon = icons.battery.charging
    elseif charge then     icon = icon_for_charge(charge)
    else                   icon = icons.battery._0
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
