local colors    = require("colors")
local settings  = require("settings")
local app_icons = require("helpers.app_icons")

local MAX_SPACES = 10
-- Spaces 1-8 are permanent; only higher ones may be destroyed (mirrors skhdrc)
local PERMANENT_SPACES = 8

-- ── Space Items ───────────────────────────────────────────────────────────────
local spaces = {}

local bg = {
  color         = colors.liquid_glass.clear,
  height        = 22,
  border_width  = 0,
  corner_radius = 12,
  drawing       = false,
}
local sel_bg = {
  color         = colors.liquid_glass.selected.bg,
  height        = 22,
  border_width  = 0,
  corner_radius = 12,
  drawing       = true,
}

for i = 1, MAX_SPACES do
  local space = sbar.add("space", "space." .. i, {
    space = i,
    icon = {
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
    background    = bg,
    padding_left  = (i == 1) and 5 or 0,
  })

  spaces[i] = space

  space:subscribe("space_change", function(env)
    local selected = env.SELECTED == "true"
    space:set({
      icon       = { highlight = selected },
      label      = { highlight = selected },
      background = selected and sel_bg or bg,
    })
  end)

  space:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "right" then
      if tonumber(env.SID) > PERMANENT_SPACES then
        sbar.exec("yabai -m space --destroy " .. env.SID)
      end
    elseif env.SELECTED ~= "true" then
      sbar.exec("yabai -m space --focus " .. env.SID)
    end
  end)
end

-- Closing pad after the last visible space (spaces 9/10 are hidden when absent,
-- so the right padding can't live on a fixed space item)
sbar.add("item", "spaces.end_pad", { width = 5 })

-- ── Spaces Bracket ────────────────────────────────────────────────────────────
-- Wraps the apple logo and all space items in a single frosted-glass pill
sbar.add("bracket", "spaces", { "apple_logo", "/space\\..*/", "spaces.end_pad" }, {
  background = {
    color         = colors.with_alpha(colors.liquid_glass.tint, 0.20),
    corner_radius = 15,
    height        = 30,
    border_width  = 1,
    border_color  = colors.liquid_glass.border,
  },
})

-- ── Window Observer ───────────────────────────────────────────────────────────
-- Sorted so the icon order stays stable across refreshes
local function icon_line_for(app_set)
  local apps = {}
  for app in pairs(app_set) do table.insert(apps, app) end
  table.sort(apps)

  local line = ""
  for _, app in ipairs(apps) do
    line = line .. (app_icons[app] or app_icons["Default"])
  end
  return line
end

local function set_space_label(index, line)
  local space = spaces[index]
  -- Native fullscreen apps and extra displays can produce indices beyond MAX_SPACES
  if not space then return end
  space:set({ label = line })
end

local space_window_observer = sbar.add("item", { drawing = false, updates = true })

space_window_observer:subscribe("space_windows_change", function(env)
  set_space_label(env.INFO.space, icon_line_for(env.INFO.apps))
end)

-- force_space_refresh is a named event triggered by yabai signals for apps
-- (e.g. Claude Desktop) that don't emit space_windows_change reliably
sbar.add("event", "force_space_refresh")

space_window_observer:subscribe("force_space_refresh", function(_)
  for i = 1, MAX_SPACES do
    -- sbar.exec decodes JSON output, so `windows` is a Lua table here
    sbar.exec("yabai -m query --windows --space " .. i .. " 2>/dev/null", function(windows)
      if type(windows) ~= "table" then return end
      local apps = {}
      for _, w in ipairs(windows) do
        -- Match space_windows_change, which ignores minimized and hidden windows
        if not w["is-minimized"] and not w["is-hidden"] then
          apps[w.app] = true
        end
      end
      set_space_label(i, icon_line_for(apps))
    end)
  end
end)
