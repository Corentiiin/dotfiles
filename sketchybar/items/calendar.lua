local settings = require("settings")
local colors   = require("colors")
local hover    = require("helpers.hover")

-- ── Clock (date + time in one label, macOS menu bar style) ───────────────────
local calendar = sbar.add("item", "calendar", {
  position      = "right",
  padding_left  = 2,
  padding_right = 0,
  icon = { drawing = false },
  label = {
    font = {
      family = settings.font.text,
      -- Semibold keeps the floating text legible on light wallpapers
      style  = settings.font.style_map["Semibold"],
      size   = 13.0,
    },
    color         = colors.label,
    padding_left  = 10,
    padding_right = 10,
  },
  background   = { drawing = true, color = colors.transparent },
  click_script = "open -a 'Calendar'",
})

hover(calendar)

local function update_calendar()
  -- "Sat Oct 31  15:20": Apple separates date and time with a wider gap
  local date = os.date("%a %b %e"):gsub("%s+", " ")
  calendar:set({ label = { string = date .. "  " .. os.date("%H:%M") } })
end

-- clock_tick comes from helpers/bar_events at second 00 of every minute
sbar.add("event", "clock_tick")
calendar:subscribe({ "clock_tick", "forced", "system_woke" }, function(_) update_calendar() end)

update_calendar()
