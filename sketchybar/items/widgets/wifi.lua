local icons  = require("icons")
local colors = require("colors")

local wifi = sbar.add("item", "widgets.wifi.padding", {
  position     = "right",
  padding_left = 4,   -- inter-item gap between volume and wifi
  icon         = { padding_left = 5, padding_right = 5 },
  label        = { drawing = false },
})

local wifi_bracket = sbar.add("bracket", "widgets.wifi.bracket", {
  wifi.name,
}, {
  background = { color = colors.transparent },
})

-- ── Update ─────────────────────────────────────────────────────────────────────
-- The Wi-Fi hardware interface (e.g. en0) essentially never changes at runtime,
-- so it's resolved once and cached instead of being re-derived on every event.
local iface_cache = nil

local function query_ipconfig()
  -- ipconfig getsummary is reliable on macOS 26+ (networksetup broken on Tahoe)
  sbar.exec("ipconfig getsummary \"" .. iface_cache .. "\" 2>/dev/null", function(result)
    result = result or ""
    local ssid      = (result:match("SSID : ([^\n]+)") or ""):gsub("^%s*", ""):gsub("%s*$", "")
    local router_ip = (result:match("[Rr]outer : ([^\n]+)") or ""):gsub("^%s*", ""):gsub("%s*$", "")
    local connected = ssid ~= ""

    local sl = ssid:lower()
    -- Primary: iPhone hotspot = 172.20.10.0/28, Android = 192.168.43.x
    -- Fallback: SSID keyword matching for custom names
    local is_hotspot = router_ip:match("^172%.20%.10%.")
                    or router_ip:match("^192%.168%.43%.")
                    or sl:match("iphone") or sl:match("hotspot")
                    or sl:match("personal") or sl:match("partage")
                    or sl:match("ipad") or sl:match("android")

    local icon = connected and (is_hotspot and icons.wifi.hotspot or icons.wifi.router)
                           or icons.wifi.disconnected

    wifi:set({
      icon = {
        string = icon,
        color  = connected and colors.blue or colors.white,
        background = {
          color         = colors.liquid_glass.selected.bg,
          height        = 22,
          corner_radius = 12,
          drawing       = connected,
        },
      },
    })
  end)
end

local function update_wifi()
  if iface_cache then
    query_ipconfig()
    return
  end

  sbar.exec(
    "networksetup -listallhardwareports 2>/dev/null"
    .. " | awk '/Wi-Fi/{getline; print $2; exit}'",
    function(result)
      iface_cache = (result or ""):gsub("%s*$", "")
      if iface_cache == "" then iface_cache = nil; return end
      query_ipconfig()
    end
  )
end

wifi:subscribe({ "wifi_change", "system_woke", "forced" }, function(_) update_wifi() end)

update_wifi()
