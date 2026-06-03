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
  update_freq  = 60,
  click_script = "open -a 'Calendar'",
})

-- ── Update Function ───────────────────────────────────────────────────────────
local function trim(s) return (s or ""):gsub("^%s*(.-)%s*$", "%1") end

local function update_calendar()
  sbar.exec("date '+%a %b %e'", function(d)
    local ds = trim(d):gsub("%s+", " ")
    if ds == "" then ds = os.date("%a %b %d") end
    calendar:set({ icon = { string = ds } })
  end)
  sbar.exec("date '+%H:%M'", function(t)
    local ts = trim(t)
    if ts == "" then ts = os.date("%H:%M") end
    calendar:set({ label = { string = ts } })
  end)
end

calendar:subscribe({ "forced", "routine", "system_woke" }, function(_) update_calendar() end)

-- ── Calendar Bracket ──────────────────────────────────────────────────────────
-- Same style as the spaces bracket on the left for visual consistency
local function hex(v) return string.format("0x%08x", v) end
sbar.exec(table.concat({
  "sketchybar",
  "--add", "bracket", "calendar_group", "calendar",
  "--set", "calendar_group",
    "background.color="        .. hex(colors.with_alpha(colors.liquid_glass.tint, 0.20)),
    "background.corner_radius=12",
    "background.height=30",
    "background.border_width=1",
    "background.border_color=" .. hex(colors.liquid_glass.border),
}, " "))

-- Gap between calendar and system-widget bracket
sbar.add("item", "spacer.calendar_gap", {
  position   = "right",
  background = { color = colors.transparent, drawing = true },
  drawing    = true,
  width      = 8,
})

update_calendar()
