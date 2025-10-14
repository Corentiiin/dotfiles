-- Item to display the current date and time in a calendar forma

local settings = require("settings")
local colors = require("colors")

local cal_time = sbar.add("item", "calendar.time", {
  position = "right",
  label = {
    color = colors.blue,
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 13
    },
    align = "center",
    background = {
      color = colors.liquid_glass.selected.bg or colors.selected_bg,
      height = 22,
      border_width = 0,
      border_color = colors.liquid_glass.glow,
      corner_radius = 12,
      drawing = true,
      width = 64,
    },
    padding_left = 6,
    padding_right = 6,
  },
  drawing = true,
  update_freq = 60, -- met à jour toutes les 60 secondes
})

-- create two separate items: date and time
local cal_date = sbar.add("item", "calendar.date", {
  position = "right",
  icon = {
    padding_left = 8,
    font = { size = 13 },
    color = colors.liquid_glass.fg,
  },
  label = { drawing = false },
  drawing = true,
  click_script = "open -a 'Calendar'",
  update_freq = 60, -- met à jour aussi la date chaque minute (safe)
})

-- trim function to clean up shell responses
local function trim(s) return (s or ""):gsub("^%s*(.-)%s*$", "%1") end

-- update function writes to both items
local function update_calendar()
  -- date (e.g. "Mon Oct  9") via system date to match macOS timezone
  sbar.exec("date '+%a %b %e'", function(d)
    local ds = trim(d)
    ds = ds:gsub("%s+", " ") -- collapse multiple spaces
    if ds == "" then ds = os.date("%a %b %d") end -- fallback
    cal_date:set({ icon = { string = ds } })
  end)

  -- time (HH:MM) via system date to match macOS
  sbar.exec("date '+%H:%M'", function(t)
    local ts = trim(t)
    if ts == "" then ts = os.date("%H:%M") end -- fallback
    cal_time:set({ label = { string = ts } })
  end)
end

-- subscribe to same events as before
cal_date:subscribe({ "forced", "routine", "system_woke", "update" }, function(_) update_calendar() end)
cal_time:subscribe({ "forced", "routine", "system_woke", "update" }, function(_) update_calendar() end)

local function hex(v) return string.format("0x%08x", v) end
local bracket_cmd = table.concat({
  "sketchybar",
  "--add", "bracket", "calendar_group", "calendar.date", "calendar.time", 
  "--set", "calendar_group",
    "background.color=" .. hex(colors.with_alpha(colors.liquid_glass.tint, 0.20)),
    "background.corner_radius=12",
    "background.height=30",
    "background.border_width=1",
    "background.border_color=" .. hex(colors.liquid_glass.border),
    "margin_left=1000",
}, " ")

sbar.exec(bracket_cmd)

-- add an invisible spacer right after the calendar_group so it appears between that bracket and the next one
sbar.add("item", "spacer.calendar_gap", {
  position = "right",
  background = { color = colors.transparent, drawing = true },
  drawing = true,
  width = 4,
})

-- initial update
update_calendar()
