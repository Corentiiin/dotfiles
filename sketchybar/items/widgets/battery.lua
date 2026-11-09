local icons    = require("icons")
local colors   = require("colors")
local settings = require("settings")
local hover    = require("helpers.hover")
local Menu     = require("helpers.menu")

-- Menu bar extra + popup modelled on the macOS 26 Battery menu:
-- title with the charge, power source and time estimate, settings link

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
  background = { drawing = true, color = colors.transparent },
})

local menu = Menu.new(battery)
hover(battery, function() return menu.is_open end)

-- ── State ─────────────────────────────────────────────────────────────────────
local state = { percent = nil, charging = false, ac = false, low_power = false }

local function icon_for_charge(charge)
  if     charge > 80 then return icons.battery._100
  elseif charge > 60 then return icons.battery._75
  elseif charge > 40 then return icons.battery._50
  elseif charge > 20 then return icons.battery._25
  else                    return icons.battery._0
  end
end

local function paint()
  local charge = state.percent

  local icon
  if state.charging then icon = icons.battery.charging
  elseif charge then     icon = icon_for_charge(charge)
  else                   icon = icons.battery._0
  end

  -- Like macOS: green while charging, yellow in Low Power Mode, red when low
  local glyph_color = colors.label
  if state.charging then
    glyph_color = colors.green
  elseif state.low_power then
    glyph_color = colors.yellow
  elseif charge and charge <= 20 then
    glyph_color = colors.red
  end

  battery:set({
    icon  = { string = charge and (charge .. " %") or "–" },
    label = { string = icon, color = glyph_color },
  })
end

-- `pmset -g batt`:
--   Now drawing from 'Battery Power'
--    -InternalBattery-0 (id=…)	49%; discharging; 8:57 remaining present: true
local function parse_pmset(output)
  output = tostring(output or "")
  local percent, status, estimate = output:match("(%d+)%%; ([^;]+); ([^\n]*)")
  return {
    percent  = tonumber(percent),
    status   = status or "",
    ac       = output:find("'AC Power'", 1, true) ~= nil,
    estimate = (estimate or ""):match("(%d+:%d+)"),
  }
end

-- Read once at load, before the first frame, so the bar never shows an empty
-- battery; afterwards battery_change keeps it up to date
do
  local pipe = io.popen("pmset -g batt 2>/dev/null")
  if pipe then
    local now = parse_pmset(pipe:read("a"))
    pipe:close()
    state.percent  = now.percent
    state.ac       = now.ac
    state.charging = now.status == "charging" or now.status == "finishing charge"
  end
  paint()
end

-- ── Popup ─────────────────────────────────────────────────────────────────────
local function hours_minutes(estimate)
  local hours, minutes = estimate:match("(%d+):(%d+)")
  hours, minutes = tonumber(hours), tonumber(minutes)
  if hours == 0 then return minutes .. " min" end
  return hours .. " h " .. string.format("%02d", minutes)
end

local function build(m, now)
  m:title("Battery", nil, state.percent and (state.percent .. " %") or nil)
  m:info("Power Source: " .. (state.ac and "Power Adapter" or "Battery"))

  if now.status == "charged" then
    m:info("Fully Charged")
  elseif now.estimate and now.estimate ~= "0:00" then
    m:info(state.charging and (hours_minutes(now.estimate) .. " until full")
                           or (hours_minutes(now.estimate) .. " remaining"))
  elseif state.ac and not state.charging then
    m:info("Not Charging")
  end
  if state.low_power then m:info("Low Power Mode: On") end

  m:separator()
  m:action("Battery Settings…", function(_)
    menu:close()
    sbar.exec("open 'x-apple.systempreferences:com.apple.Battery-Settings.extension'")
  end)
end

local function close_menu()
  menu:close()
  battery:set({ background = { color = colors.transparent } })
end

battery:subscribe("mouse.clicked", function(_)
  if menu.is_open then close_menu(); return end
  -- The time estimate is only needed here, so it is read when the menu opens
  sbar.exec("pmset -g batt 2>/dev/null", function(output)
    local now = parse_pmset(output)
    menu:open(function(m) build(m, now) end)
    battery:set({ background = { color = colors.highlight } })
  end)
end)

battery:subscribe("mouse.exited.global", close_menu)

-- ── Live Updates ──────────────────────────────────────────────────────────────
-- battery_change comes from helpers/bar_events as soon as macOS updates the
-- power source (PERCENT, CHARGING, AC, LPM), so nothing is polled
sbar.add("event", "battery_change")

battery:subscribe("battery_change", function(env)
  state.percent   = tonumber(env.PERCENT)
  state.charging  = env.CHARGING == "1"
  state.ac        = env.AC == "1"
  state.low_power = env.LPM == "1"
  paint()
end)

-- After a reload or wake, ask the helper to resend the current state
battery:subscribe({ "forced", "system_woke" }, function(_)
  sbar.exec("pkill -USR1 -x bar_events")
end)
