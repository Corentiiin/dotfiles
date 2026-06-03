local colors = require("colors")
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
  sbar.animate("linear", 8, function()
    front_app:set({ label = { string = "􀯻  " .. name } })
  end)
end

front_app:subscribe("front_app_switched", function(env)
  set_app(env.INFO)
end)

-- Populate label immediately on startup without waiting for the first app switch
sbar.exec(
  'osascript -e \'tell application "System Events" to get name of first process where frontmost is true\'',
  function(name)
    name = name:gsub("%s+$", "")
    if name ~= "" then set_app(name) end
  end
)
