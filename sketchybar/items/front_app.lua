local colors = require("colors")
local settings = require("settings")
local hover = require("helpers.hover")

-- Bold application name, exactly like the native menu bar; clicking it opens
-- the application menu
local front_app = sbar.add("item", "front_app", {
  display       = "active",
  padding_left  = 8,
  padding_right = 0,
  icon = { drawing = false },
  label = {
    font = {
      family = settings.font.text,
      style  = settings.font.style_map["Bold"],
      size   = 13.0,
    },
    color         = colors.label,
    padding_left  = 10,
    padding_right = 10,
  },
  background   = { drawing = true, color = colors.transparent },
  updates      = true,
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 1",
})

hover(front_app)

local function set_app(name)
  front_app:set({ label = { string = name } })
end

front_app:subscribe("front_app_switched", function(env)
  set_app(env.INFO)
end)

-- Populate label immediately on startup without waiting for the first app switch
-- (lsappinfo needs no Automation permission, unlike osascript + System Events)
sbar.exec('lsappinfo info -only name "$(lsappinfo front)"', function(result)
  local name = tostring(result or ""):match('"LSDisplayName"="(.-)"')
  if name and name ~= "" then set_app(name) end
end)
