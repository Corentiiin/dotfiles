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
  -- Short interval: routine ticks aren't aligned to the minute, so 60 s could
  -- leave the clock up to a minute behind. os.date is cheap (no process spawn).
  update_freq  = 10,
  click_script = "open -a 'Calendar'",
})

hover(calendar)

local function update_calendar()
  -- "Sat Oct 31  15:20": Apple separates date and time with a wider gap
  local date = os.date("%a %b %e"):gsub("%s+", " ")
  calendar:set({ label = { string = date .. "  " .. os.date("%H:%M") } })
end

calendar:subscribe({ "forced", "routine", "system_woke" }, function(_) update_calendar() end)

update_calendar()
