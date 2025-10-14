-- Widget to display Wi-Fi status and details in SketchyBar

local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local wifi = sbar.add("item", "widgets.wifi.padding", {
  position = "right",
  align = "center",
  icon = {
    padding_left = 6,
  },
  label = {
    padding_right = 6,
  },
})

wifi:subscribe({"wifi_change", "system_woke"}, function(env)
  -- get SSID first to detect Personal Hotspot (iPhone) and connectivity
  sbar.exec("networksetup -getairportnetwork en0", function(ssid_info)
    local connected = false
    local ssid = ""
    if ssid_info and ssid_info:match(":") then
      -- format: "Current Wi-Fi Network: SSID_NAME"
      ssid = ssid_info:match(": (.+)") or ""
      connected = ssid ~= nil and ssid ~= ""
    end

    -- fallback: check IP on several interfaces if SSID parsing fails
    if not connected then
      -- try common interfaces (en0,en1,en2) and return first non-empty IP
      local ip_cmd = [[sh -c "ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || ipconfig getifaddr en2 2>/dev/null"]]
      sbar.exec(ip_cmd, function(ip)
        connected = not (ip == "" or ip == nil)
        -- continue to set icon after IP check
        local s = (ssid or ""):lower()
        local is_hotspot = s:match("iphone") or s:match("hotspot") or s:match("personal")
        local wifi_icon = icons.wifi.disconnected
        local color = colors.white
        if connected then
          -- prefer hotspot icon if available
          wifi_icon = (is_hotspot and (icons.wifi.hotspot or icons.wifi.connected)) or icons.wifi.connected
          color = colors.blue
        end
        wifi:set({
          align = "center",
          icon = {
            string = wifi_icon,
            color = color,
            background = {
              color = colors.liquid_glass.selected.bg or colors.selected_bg,
              height = 22,
              border_width = 0,
              border_color = colors.liquid_glass.glow,
              corner_radius = 12,
              drawing = true,
            },
            padding_right = 6
          },
        })
      end)
      return
    end

    local s = (ssid or ""):lower()
    local is_hotspot = s:match("iphone") or s:match("hotspot") or s:match("personal")
    local wifi_icon = (is_hotspot and (icons.wifi.hotspot or icons.wifi.connected)) or icons.wifi.connected
    wifi:set({
      icon = {
        align = "center",
        string = wifi_icon,
        color = colors.blue,
        background = {
          color = colors.liquid_glass.selected.bg or colors.selected_bg,
          height = 22,
          border_width = 0,
          border_color = colors.liquid_glass.glow,
          corner_radius = 12,
          drawing = true,
        },
      },
    })
  end)
end)
