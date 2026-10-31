local icons  = require("icons")
local colors = require("colors")
local hover  = require("helpers.hover")
local Menu   = require("helpers.menu")

-- Menu bar extra + popup modelled on the macOS 26 Wi-Fi menu:
-- title with power toggle, current network with its details, settings link

local wifi = sbar.add("item", "widgets.wifi", {
  position      = "right",
  padding_left  = 2,
  padding_right = 2,
  icon = {
    font          = { size = 16.0 },
    padding_left  = 9,
    padding_right = 9,
  },
  label      = { drawing = false },
  background = { drawing = true, color = colors.transparent },
})

local menu = Menu.new(wifi)
hover(wifi, function() return menu.is_open end)

-- ── State ─────────────────────────────────────────────────────────────────────
-- The Wi-Fi hardware interface (e.g. en0) essentially never changes at runtime,
-- so it's resolved once and cached instead of being re-derived on every event.
local iface = nil
local state = { power = true, connected = false, hotspot = false }

local function field(text, key)
  return ((text:match(key .. " : ([^\n]+)") or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local SECURITY = { WPA2_PSK = "WPA2 Personal", WPA3_SAE = "WPA3 Personal", NONE = "None" }

local function read_state(callback)
  -- ipconfig getsummary is reliable on macOS 26+ (networksetup -getairportnetwork is broken on Tahoe)
  sbar.exec(
    "ipconfig getsummary " .. iface .. " 2>/dev/null; echo '--'; "
    .. "networksetup -getairportpower " .. iface .. " 2>/dev/null; ipconfig getifaddr " .. iface .. " 2>/dev/null",
    function(result)
      result = tostring(result or "")
      local summary, rest = result:match("^(.-)\n%-%-\n(.*)$")
      summary, rest = summary or "", rest or ""

      local ssid = field(summary, "SSID")
      state.power     = rest:match("Power %b(): On") ~= nil
      -- macOS 26 reports "SSID : <redacted>": the name is hidden but its
      -- presence still tells whether Wi-Fi is associated
      state.connected = state.power and ssid ~= ""
      state.ssid      = (ssid ~= "" and ssid ~= "<redacted>") and ssid or nil
      state.router    = field(summary, "Router")
      state.security  = field(summary, "Security")
      state.ip        = rest:match("(%d+%.%d+%.%d+%.%d+)")
      -- SSID names are redacted, so hotspots are detected by router subnet:
      -- iPhone hotspot = 172.20.10.0/28, Android = 192.168.43.x
      state.hotspot = state.router:match("^172%.20%.10%.") ~= nil
                   or state.router:match("^192%.168%.43%.") ~= nil
      callback()
    end
  )
end

local function paint()
  local icon = state.connected and (state.hotspot and icons.wifi.hotspot or icons.wifi.router)
                               or icons.wifi.disconnected
  -- Monochrome like every macOS menu bar extra; dimmed when offline
  wifi:set({ icon = { string = icon, color = state.connected and colors.label or colors.tertiary_label } })
end

local function update()
  if iface then
    read_state(function() paint(); menu:refresh() end)
    return
  end
  sbar.exec("networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi/{getline; print $2; exit}'", function(result)
    iface = tostring(result or ""):gsub("%s+$", "")
    if iface == "" then iface = nil; return end
    update()
  end)
end

-- ── Popup ─────────────────────────────────────────────────────────────────────
local function build(m)
  m:title("Wi-Fi", {
    on = state.power,
    on_click = function(_)
      sbar.exec("networksetup -setairportpower " .. iface .. (state.power and " off" or " on"), function(_)
        update()
      end)
    end,
  })

  if state.power then
    m:separator()
    if state.connected then
      m:header(state.hotspot and "Personal Hotspot" or "Known Network")
      m:circle_row(state.ssid or "Connected", state.hotspot and icons.wifi.hotspot or icons.wifi.router, true)
      if state.ip then m:detail("IP Address", state.ip) end
      if state.router ~= "" then m:detail("Router", state.router) end
      if state.security ~= "" then m:detail("Security", SECURITY[state.security] or state.security:gsub("_", " ")) end
    else
      m:info("Not connected")
    end
  end

  m:separator()
  m:action("Wi-Fi Settings…", function(_)
    menu:close()
    sbar.exec("open 'x-apple.systempreferences:com.apple.wifi-settings-extension'")
  end)
end

local function close_menu()
  menu:close()
  wifi:set({ background = { color = colors.transparent } })
end

wifi:subscribe("mouse.clicked", function(_)
  if menu.is_open then close_menu(); return end
  if not iface then return end
  -- Fresh state first so the menu opens with current details
  read_state(function()
    paint()
    menu:open(build)
    wifi:set({ background = { color = colors.highlight } })
  end)
end)

wifi:subscribe("mouse.exited.global", close_menu)
wifi:subscribe({ "wifi_change", "system_woke", "forced" }, function(_) update() end)

update()
