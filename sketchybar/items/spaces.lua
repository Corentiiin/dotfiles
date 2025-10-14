local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}
local space_labels = {}
local children = {}

-- create a native sketchybar bracket "spaces" that matches all space.* items
local function hex(v) return string.format("0x%08x", v) end
local bracket_cmd = table.concat({
  "sketchybar",
  "--add", "bracket", "spaces", "apple_logo", "'/space\\..*/'",

  "--set", "spaces",
    "background.color=" .. hex(colors.with_alpha(colors.liquid_glass.tint, 0.20)),
    "background.corner_radius=12",
    "background.height=30",
    "background.border_width=1",
    "background.border_color=" .. hex(colors.liquid_glass.border),
}, " ")

sbar.exec(bracket_cmd)

for i = 1, 10, 1 do
  -- create per-index backgrounds (hidden by default, shown when selected)
  local idx = i
  local bg = {
    color = colors.liquid_glass.clear,
    height = 22,
    border_width = 0,
    border_color = colors.liquid_glass.border,
    corner_radius = 12,
    drawing = false,                              -- hidden by default
    padding_left = (idx == 1) and 5 or 0,
    padding_right = (idx == 8) and 5 or 0,
  }

  local sel_bg = {
    color = colors.liquid_glass.selected.bg or colors.selected_bg,
    height = 22,
    border_width = 0,
    border_color = colors.liquid_glass.glow,
    corner_radius = 12,
    drawing = true,
    padding_left = (idx == 1) and 5 or 0,
    padding_right = (idx == 8) and 5 or 0,
  }

  local space = sbar.add("space", "space." .. idx, {
    space = i,
    icon = {
      font = { family = settings.font.typeface, size = 13.0 },
      string = i,
      padding_left = 10,
      padding_right = 3,
      color = colors.white,
      highlight_color = colors.blue,
    },
    label = {
      padding_left = 3,
      padding_right = 10,
      color = colors.white,
      highlight_color = colors.blue,   -- couleur utilisée quand highlight=true
      font = "sketchybar-app-font:Regular:13.0",
    },
    background = bg, -- start with hidden bg; sel_bg will be applied when selected
  })

  spaces[idx] = space
  space_labels[idx] = " "

  -- ensure the space is a child of the bracket
  space:set({ parent = "spaces" })

  -- capture idx for the closure (already captured above)
  space:subscribe("space_change", function(env)
    local selected = env.SELECTED == "true"
    space:set({
      icon = {
        highlight = selected,
        color = selected and colors.blue or colors.white,
      },
      label = {
        highlight = selected,
        color = selected and colors.blue or colors.white,
      },
      background = (selected and sel_bg) or bg,
    })
  end)

  space:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "other" then
      space_popup:set({ background = { image = "space." .. env.SID } })
      space:set({ popup = { drawing = "toggle" } })
    else
      local op = (env.BUTTON == "right") and "--destroy" or "--focus"
      sbar.exec("yabai -m space " .. op .. " " .. env.SID)
    end
  end)

  space:subscribe("mouse.exited", function(_)
    space:set({ popup = { drawing = false } })
  end)
end

local space_window_observer = sbar.add("item", {
  drawing = false,
  updates = true,
})

space_window_observer:subscribe("space_windows_change", function(env)
  
  local icon_line = ""
  local no_app = true
  for app, count in pairs(env.INFO.apps) do
    no_app = false

    local lookup = app_icons[app]
    local icon = ((lookup == nil) and app_icons["Default"] or lookup)
    icon_line = icon_line .. icon
  end

  if (no_app) then
    icon_line = ""
  end

  -- update tracked label then animate and resize container
  space_labels[env.INFO.space] = icon_line
  sbar.animate("tanh", 8, function()
    spaces[env.INFO.space]:set({ label = icon_line })
  end)
end)