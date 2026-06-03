local colors      = require("colors")
local icons       = require("icons")
local settings    = require("settings")

local popup_width = 200

local volume_icon = sbar.add("item", "widgets.volume1", {
  position     = "right",
  padding_left = 10,  -- left margin inside the sys_status bracket (matches spaces outer padding)
  icon = {
    string        = icons.volume._100,
    padding_right = 6,
  },
})

local volume_bracket = sbar.add("bracket", "widgets.volume.bracket", {
  volume_icon.name,
}, {
  background = { color = colors.transparent },
})

-- ── Icon Helpers ───────────────────────────────────────────────────────────────
local function icon_for_volume(v)
  if     v > 75 then return icons.volume._100
  elseif v > 35 then return icons.volume._66
  elseif v > 15 then return icons.volume._33
  elseif v > 0  then return icons.volume._10
  else                return icons.volume._0
  end
end

-- Map output device name to SF Symbol icon; fall back to volume-level icon
local function icon_for_device(device, volume)
  local d = (device or ""):lower()
  if     d:match("airpods pro")  then return icons.audio.airpods_pro
  elseif d:match("airpods max")  then return icons.audio.airpods_max
  elseif d:match("airpods")      then return icons.audio.airpods
  elseif d:match("homepod")
      or d:match("hifi")
      or d:match("studio display") then return icons.audio.homepod
  else   return icon_for_volume(volume)
  end
end

-- ── Device Tracking ───────────────────────────────────────────────────────────
local current_device = ""
local current_volume = 0

local function refresh_icon()
  volume_icon:set({ icon = { string = icon_for_device(current_device, current_volume) } })
end

local function refresh_device()
  sbar.exec("SwitchAudioSource -t output -c 2>/dev/null", function(result)
    current_device = result:gsub("%s+$", ""):gsub("^%s+", "")
    refresh_icon()
  end)
end

-- ── Live Updates ──────────────────────────────────────────────────────────────
volume_icon:subscribe("volume_change", function(env)
  current_volume = tonumber(env.INFO) or 0
  refresh_device()  -- also re-check device on each volume event
end)

volume_icon:subscribe("system_woke", function(_)
  refresh_device()
end)

-- Scroll on the icon adjusts system volume (ctrl = fine, no modifier = coarse)
volume_icon:subscribe("scroll", function(env)
  local delta = env.INFO.delta
  if not (env.INFO.modifier == "ctrl") then delta = delta * 10.0 end
  sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end)

-- ── Popup: device picker + slider ─────────────────────────────────────────────
sbar.add("slider", popup_width, {
  position = "popup." .. volume_bracket.name,
  slider = {
    highlight_color = colors.blue,
    background = {
      height        = 6,
      corner_radius = 3,
      color         = colors.bg2,
    },
    knob = { string = "􀀁", drawing = true },
  },
  background  = { color = colors.bg1, height = 2, y_offset = -20 },
  click_script = 'osascript -e "set volume output volume $PERCENTAGE"',
})

local function volume_collapse()
  if volume_bracket:query().popup.drawing == "off" then return end
  volume_bracket:set({ popup = { drawing = false } })
  volume_icon:set({ background = { color = colors.transparent } })
  sbar.remove('/volume.device\\.*/')
end

local function volume_toggle(env)
  if env.BUTTON == "right" then
    sbar.exec("open /System/Library/PreferencePanes/Sound.prefpane")
    return
  end

  if volume_bracket:query().popup.drawing == "off" then
    volume_bracket:set({ popup = { drawing = true } })
    volume_icon:set({ background = { color = colors.selected_bg } })
    sbar.exec("SwitchAudioSource -t output -c 2>/dev/null", function(result)
      current_device = result:gsub("%s+$", ""):gsub("^%s+", "")
      refresh_icon()
      sbar.exec("SwitchAudioSource -a -t output 2>/dev/null", function(available)
        local counter = 0
        for device in available:gmatch("[^\r\n]+") do
          local color = (device == current_device) and colors.white or colors.grey
          sbar.add("item", "volume.device." .. counter, {
            position = "popup." .. volume_bracket.name,
            width    = popup_width,
            align    = "center",
            label    = { string = device, color = color },
            click_script = 'SwitchAudioSource -s "' .. device .. '"'
              .. ' && sketchybar --set /volume.device\\.*/ label.color=' .. colors.grey
              .. ' --set $NAME label.color=' .. colors.white,
          })
          counter = counter + 1
        end
      end)
    end)
  else
    volume_collapse()
  end
end

volume_icon:subscribe("mouse.clicked",       volume_toggle)
volume_icon:subscribe("mouse.exited.global", volume_collapse)

-- ── Startup State ─────────────────────────────────────────────────────────────
sbar.exec('osascript -e "output volume of (get volume settings)"', function(vol)
  current_volume = tonumber((vol or ""):gsub("%s+", "")) or 0
  refresh_device()
end)
