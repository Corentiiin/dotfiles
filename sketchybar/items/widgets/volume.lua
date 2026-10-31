local colors = require("colors")
local icons  = require("icons")
local hover  = require("helpers.hover")
local Menu   = require("helpers.menu")

-- Menu bar extra + popup modelled on the macOS 26 Sound menu:
-- title, volume slider, "Output" section with round device buttons, settings link

local volume = sbar.add("item", "widgets.volume", {
  position      = "right",
  padding_left  = 2,
  padding_right = 2,
  icon = {
    string        = icons.volume._100,
    font          = { size = 15.0 },
    padding_left  = 9,
    padding_right = 9,
  },
  label      = { drawing = false },
  background = { drawing = true, color = colors.transparent },
})

local menu = Menu.new(volume)
hover(volume, function() return menu.is_open end)

-- ── Icon Helpers ──────────────────────────────────────────────────────────────
local function icon_for_volume(v)
  if     v > 75 then return icons.volume._100
  elseif v > 35 then return icons.volume._66
  elseif v > 15 then return icons.volume._33
  elseif v > 0  then return icons.volume._10
  else                return icons.volume._0
  end
end

-- Map output device name to SF Symbol icon; fall back to volume-level icon
local function icon_for_device(device, level)
  local d = (device or ""):lower()
  if     d:match("airpods pro")  then return icons.audio.airpods_pro
  elseif d:match("airpods max")  then return icons.audio.airpods_max
  elseif d:match("airpods")      then return icons.audio.airpods
  elseif d:match("homepod")
      or d:match("hifi")
      or d:match("studio display") then return icons.audio.homepod
  else   return icon_for_volume(level)
  end
end

-- Glyph inside the round device button of the popup
local function glyph_for_device(device)
  local d = (device or ""):lower()
  if     d:match("airpods pro") then return icons.audio.airpods_pro
  elseif d:match("airpods max") then return icons.audio.airpods_max
  elseif d:match("airpods")     then return icons.audio.airpods
  elseif d:match("homepod")     then return icons.audio.homepod
  elseif d:match("macbook")     then return icons.audio.laptop
  elseif d:match("display") or d:match("monitor") then return icons.audio.display
  else                               return icons.audio.speaker
  end
end

-- ── State ─────────────────────────────────────────────────────────────────────
local current_device = ""
local current_volume = 0
local devices        = {}
local slider         = nil -- popup slider while the menu is open

local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

local function refresh_icon()
  volume:set({ icon = { string = icon_for_device(current_device, current_volume) } })
end

local function refresh_device()
  sbar.exec("SwitchAudioSource -t output -c 2>/dev/null", function(result)
    current_device = trim(result)
    refresh_icon()
  end)
end

-- ── Popup ─────────────────────────────────────────────────────────────────────
local function build(m)
  m:title("Sound")
  slider = m:slider(current_volume, 'osascript -e "set volume output volume $PERCENTAGE"')
  m:separator()
  m:header("Output")
  for _, device in ipairs(devices) do
    m:circle_row(device, glyph_for_device(device), device == current_device, function(_)
      sbar.exec('SwitchAudioSource -s "' .. device:gsub('"', '\\"') .. '"', function(_)
        current_device = device
        refresh_icon()
        menu:refresh()
      end)
    end)
  end
  m:separator()
  m:action("Sound Settings…", function(_)
    menu:close()
    sbar.exec("open 'x-apple.systempreferences:com.apple.Sound-Settings.extension'")
  end)
end

local function open_menu()
  -- Load the device list first so the menu opens complete
  sbar.exec("SwitchAudioSource -t output -c 2>/dev/null; echo '--'; SwitchAudioSource -a -t output 2>/dev/null", function(result)
    local current, list = tostring(result or ""):match("^(.-)\n%-%-\n(.*)$")
    current_device = trim(current)
    devices = {}
    for device in (list or ""):gmatch("[^\r\n]+") do table.insert(devices, device) end
    refresh_icon()
    menu:open(build)
    volume:set({ background = { color = colors.highlight } })
  end)
end

local function close_menu()
  menu:close()
  volume:set({ background = { color = colors.transparent } })
end

volume:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    sbar.exec("open 'x-apple.systempreferences:com.apple.Sound-Settings.extension'")
  elseif menu.is_open then
    close_menu()
  else
    open_menu()
  end
end)

volume:subscribe("mouse.exited.global", close_menu)

-- ── Live Updates ──────────────────────────────────────────────────────────────
volume:subscribe("volume_change", function(env)
  current_volume = tonumber(env.INFO) or 0
  if menu.is_open and slider then slider:set({ slider = { percentage = current_volume } }) end
  refresh_device()  -- also re-check device on each volume event
end)

volume:subscribe("system_woke", function(_)
  refresh_device()
end)

-- Scroll on the icon adjusts system volume (ctrl = fine, no modifier = coarse)
volume:subscribe("mouse.scrolled", function(env)
  local delta = env.INFO.delta
  if not (env.INFO.modifier == "ctrl") then delta = delta * 10.0 end
  sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end)

-- ── Startup State ─────────────────────────────────────────────────────────────
sbar.exec('osascript -e "output volume of (get volume settings)"', function(vol)
  -- Extra parentheses: gsub returns (string, count) and count would become the base
  current_volume = tonumber((tostring(vol or ""):gsub("%s+", ""))) or 0
  refresh_device()
end)
