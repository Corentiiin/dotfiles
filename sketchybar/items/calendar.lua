local settings = require("settings")
local colors   = require("colors")

-- ── Calendar Item (date + time in one item) ───────────────────────────────────
local calendar = sbar.add("item", "calendar", {
  position = "right",
  icon = {
    padding_left  = 10,
    padding_right = 0,
    font  = {
      family = settings.font.text,
      style  = settings.font.style_map["Bold"],
      size   = 13,
    },
    color = colors.liquid_glass.fg,
  },
  label = {
    padding_left  = 8,
    padding_right = 10,
    font  = {
      family = settings.font.text,
      style  = settings.font.style_map["Bold"],
      size   = 13,
    },
    color = colors.liquid_glass.fg,
  },
  -- Short interval: routine ticks aren't aligned to the minute, so 60 s could
  -- leave the clock up to a minute behind. os.date is cheap (no process spawn).
  update_freq  = 10,
  click_script = "open -a 'Calendar'",
})

-- ── Update Function ───────────────────────────────────────────────────────────
local function update_calendar()
  calendar:set({
    icon  = { string = (os.date("%a %b %e"):gsub("%s+", " ")) },
    label = { string = os.date("%H:%M") },
  })
end

calendar:subscribe({ "forced", "routine", "system_woke" }, function(_) update_calendar() end)

-- ── Calendar Bracket ──────────────────────────────────────────────────────────
-- Same style as the spaces bracket on the left for visual consistency
sbar.add("bracket", "calendar_group", { calendar.name }, {
  background = {
    color         = colors.with_alpha(colors.liquid_glass.tint, 0.20),
    corner_radius = 15,
    height        = 30,
    border_width  = 1,
    border_color  = colors.liquid_glass.border,
  },
})

-- Gap between calendar and system-widget bracket
sbar.add("item", "spacer.calendar_gap", {
  position = "right",
  width    = 8,
})

update_calendar()
