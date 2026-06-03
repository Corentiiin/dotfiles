local colors    = require("colors")
local settings  = require("settings")
local app_icons = require("helpers.app_icons")

-- ── Spaces Bracket ────────────────────────────────────────────────────────────
-- Wraps the apple logo and all space items in a single frosted-glass pill
local function hex(v) return string.format("0x%08x", v) end

sbar.exec(table.concat({
  "sketchybar",
  "--add", "bracket", "spaces", "apple_logo", "'/space\\..*/'",
  "--set", "spaces",
    "background.color="        .. hex(colors.with_alpha(colors.liquid_glass.tint, 0.20)),
    "background.corner_radius=12",
    "background.height=30",
    "background.border_width=1",
    "background.border_color=" .. hex(colors.liquid_glass.border),
}, " "))

-- ── Space Items ───────────────────────────────────────────────────────────────
local spaces       = {}
local space_labels = {}

for i = 1, 10 do
  local bg = {
    color         = colors.liquid_glass.clear,
    height        = 22,
    border_width  = 0,
    corner_radius = 12,
    drawing       = false,
    padding_left  = (i == 1) and 5 or 0,
    padding_right = (i == 8) and 5 or 0,
  }
  local sel_bg = {
    color         = colors.liquid_glass.selected.bg or colors.selected_bg,
    height        = 22,
    border_width  = 0,
    border_color  = colors.liquid_glass.glow,
    corner_radius = 12,
    drawing       = true,
    padding_left  = (i == 1) and 5 or 0,
    padding_right = (i == 8) and 5 or 0,
  }

  local space = sbar.add("space", "space." .. i, {
    space = i,
    icon = {
      -- use settings.font.text (SF Pro); .typeface does not exist in default_font.lua
      font            = { family = settings.font.text, size = 13.0 },
      string          = i,
      padding_left    = 10,
      padding_right   = 3,
      color           = colors.white,
      highlight_color = colors.blue,
    },
    label = {
      padding_left    = 3,
      padding_right   = 10,
      color           = colors.white,
      highlight_color = colors.blue,
      font            = "sketchybar-app-font:Regular:13.0",
    },
    background = bg,
  })

  spaces[i]       = space
  space_labels[i] = ""

  space:subscribe("space_change", function(env)
    local selected = env.SELECTED == "true"
    space:set({
      icon       = { highlight = selected, color = selected and colors.blue or colors.white },
      label      = { highlight = selected, color = selected and colors.blue or colors.white },
      background = selected and sel_bg or bg,
    })
  end)

  space:subscribe("mouse.clicked", function(env)
    local op = (env.BUTTON == "right") and "--destroy" or "--focus"
    sbar.exec("yabai -m space " .. op .. " " .. env.SID)
  end)
end

-- ── Window Observer ───────────────────────────────────────────────────────────
-- force_space_refresh is a named event triggered by yabai signals for apps
-- (e.g. Claude Desktop) that don't emit space_windows_change reliably
sbar.add("event", "force_space_refresh")

local space_window_observer = sbar.add("item", { drawing = false, updates = true })

space_window_observer:subscribe("space_windows_change", function(env)
  local icon_line = ""
  local no_app    = true
  for app in pairs(env.INFO.apps) do
    no_app    = false
    local lookup = app_icons[app]
    icon_line = icon_line .. (lookup or app_icons["Default"])
  end

  space_labels[env.INFO.space] = no_app and "" or icon_line
  sbar.animate("tanh", 8, function()
    spaces[env.INFO.space]:set({ label = icon_line })
  end)
end)

-- Fallback: re-query yabai directly for all spaces when the event above doesn't fire
space_window_observer:subscribe("force_space_refresh", function(_)
  for i = 1, 10 do
    sbar.exec("yabai -m query --windows --space " .. i .. " 2>/dev/null", function(windows)
      local seen      = {}
      local icon_line = ""
      for app in windows:gmatch('"app"%s*:%s*"([^"]+)"') do
        if not seen[app] then
          seen[app]  = true
          local lookup = app_icons[app]
          icon_line  = icon_line .. (lookup or app_icons["Default"])
        end
      end
      space_labels[i] = icon_line
      sbar.animate("tanh", 8, function()
        spaces[i]:set({ label = icon_line })
      end)
    end)
  end
end)
