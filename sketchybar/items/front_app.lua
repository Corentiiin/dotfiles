local settings = require("settings")

local front_app = sbar.add("item", "front_app", {
  display = "active",
  icon = { drawing = false },
  label = {
    font = {
      style = settings.font.style_map["Semibold"],
      size = 12.0,
    },
  },
  updates = true,
})

local function set_app(name)
  front_app:set({ label = { string = "􀯻  " .. name } })
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
