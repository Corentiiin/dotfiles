local colors    = require("colors")
local settings  = require("settings")
local app_icons = require("helpers.app_icons")

-- Spaces drawn as an Apple segmented control: a recessed track holding one
-- segment per space (number + real app icons), the focused one raised.

local MAX_SPACES = 10
local MAX_ICONS  = 5
-- Spaces 1-8 are permanent; only higher ones may be destroyed (mirrors skhdrc)
local PERMANENT_SPACES = 8

local ICON_SCALE = 0.5 -- app images are 32 pt at scale 1
local ICON_SIZE  = 32 * ICON_SCALE
local ICON_GAP   = 2
local EDGE       = 9   -- inner padding at both ends of a segment

local number_font = {
  family = settings.font.rounded,
  style  = settings.font.style_map["Semibold"],
  size   = 12.0,
}

-- ── Items ─────────────────────────────────────────────────────────────────────
local numbers   = {} -- space index -> space item (the number)
local app_slots = {} -- space index -> { icon items }
local overflow  = {} -- space index -> "+n" item
local segments  = {} -- space index -> bracket (the segment capsule)
local state     = {} -- space index -> { selected, hovered, apps, signature }

sbar.add("item", "spaces.start_pad", { width = 2, padding_left = 0, padding_right = 0 })

for i = 1, MAX_SPACES do
  state[i] = { selected = false, hovered = false, apps = {}, signature = nil }

  numbers[i] = sbar.add("space", "space." .. i, {
    space = i,
    padding_left  = 0,
    padding_right = 0,
    icon = {
      string        = i,
      font          = number_font,
      color         = colors.tertiary_label,
      padding_left  = EDGE,
      padding_right = EDGE,
    },
    label      = { drawing = false },
    background = { drawing = false },
  })

  app_slots[i] = {}
  for j = 1, MAX_ICONS do
    app_slots[i][j] = sbar.add("item", "space." .. i .. ".app." .. j, {
      drawing       = false,
      padding_left  = 0,
      padding_right = 0,
      icon = {
        string        = "",
        padding_left  = 0,
        padding_right = ICON_GAP,
        background    = {
          drawing = true,
          color   = colors.transparent,
          image   = { scale = ICON_SCALE, drawing = true },
        },
      },
      label = { drawing = false },
    })
  end

  overflow[i] = sbar.add("item", "space." .. i .. ".more", {
    drawing       = false,
    padding_left  = 0,
    padding_right = 0,
    icon = {
      font          = { family = settings.font.rounded, style = settings.font.style_map["Bold"], size = 10.0 },
      color         = colors.secondary_label,
      padding_left  = 1,
      padding_right = EDGE,
    },
    label = { drawing = false },
  })
end

sbar.add("item", "spaces.end_pad", { width = 2, padding_left = 0, padding_right = 0 })

-- ── Track & Segments ──────────────────────────────────────────────────────────
-- The track is added first so it is drawn beneath the segments
sbar.add("bracket", "spaces.track", { "spaces.start_pad", "/space\\..*/", "spaces.end_pad" }, {
  background = {
    color         = colors.track.fill,
    border_color  = colors.track.border,
    border_width  = 1,
    corner_radius = 14,
    height        = 28,
  },
})

for i = 1, MAX_SPACES do
  local members = { numbers[i].name }
  for j = 1, MAX_ICONS do table.insert(members, app_slots[i][j].name) end
  table.insert(members, overflow[i].name)

  segments[i] = sbar.add("bracket", "segment." .. i, members, {
    background = {
      color         = colors.transparent,
      border_color  = colors.transparent,
      border_width  = 1,
      corner_radius = 12,
      height        = 24,
    },
  })
end

-- ── Styling ───────────────────────────────────────────────────────────────────
local function paint(i)
  local s = state[i]
  local fill, rim
  if s.selected then
    fill, rim = colors.segment.selected, colors.segment.selected_rim
  elseif s.hovered then
    fill, rim = colors.segment.hover, colors.transparent
  else
    fill, rim = colors.transparent, colors.transparent
  end

  local number_color = s.selected and colors.label
    or (#s.apps > 0 and colors.secondary_label or colors.tertiary_label)

  sbar.animate("tanh", 12, function()
    segments[i]:set({ background = { color = fill, border_color = rim } })
    numbers[i]:set({ icon = { color = number_color } })
  end)
end

-- ── App Icons ─────────────────────────────────────────────────────────────────
local bundle_ids = {} -- app name -> bundle id, or false when it can't be resolved
local pending    = {}

local function render(i)
  local s    = state[i]
  local apps = s.apps
  local shown = math.min(#apps, MAX_ICONS)
  local extra = #apps - shown

  local signature = {}
  for _, app in ipairs(apps) do table.insert(signature, app.name .. "=" .. tostring(bundle_ids[app.name])) end
  signature = table.concat(signature, ",")
  if signature == s.signature then return end
  s.signature = signature

  numbers[i]:set({ icon = { padding_right = (#apps > 0) and 5 or EDGE } })

  for j = 1, MAX_ICONS do
    local slot = app_slots[i][j]
    local app  = apps[j]
    if not app then
      slot:set({ drawing = false })
    else
      local last    = (j == shown) and extra == 0
      local bundle  = bundle_ids[app.name]
      local padding = last and EDGE or ICON_GAP
      if bundle then
        -- Image-only icons ignore their padding, so the gap comes from a fixed width
        slot:set({
          drawing = true,
          width   = ICON_SIZE + padding,
          icon = {
            string        = "",
            padding_right = 0,
            background    = { image = { string = "app." .. bundle, drawing = true } },
          },
        })
      else
        -- No bundle id (yet): fall back to the monochrome app-font glyph
        slot:set({
          drawing = true,
          width   = "dynamic",
          icon = {
            string        = app_icons[app.name] or app_icons["Default"],
            font          = "sketchybar-app-font:Regular:14.0",
            color         = colors.secondary_label,
            padding_right = padding,
            background    = { image = { drawing = false } },
          },
        })
      end
    end
  end

  overflow[i]:set({
    drawing = extra > 0,
    icon    = { string = "+" .. extra },
  })

  paint(i)
end

local function resolve_bundle(app)
  if bundle_ids[app.name] ~= nil or pending[app.name] then return end
  pending[app.name] = true
  sbar.exec('lsappinfo info -only bundleid "$(lsappinfo find pid=' .. app.pid .. ')"', function(result)
    pending[app.name] = nil
    bundle_ids[app.name] = tostring(result or ""):match('"CFBundleIdentifier"="(.-)"') or false
    for i = 1, MAX_SPACES do
      for _, a in ipairs(state[i].apps) do
        if a.name == app.name then render(i); break end
      end
    end
  end)
end

-- One yabai query refreshes every space (sbar.exec decodes the JSON into a table)
local function refresh()
  sbar.exec("yabai -m query --windows 2>/dev/null", function(windows)
    if type(windows) ~= "table" then return end

    local by_space = {}
    for i = 1, MAX_SPACES do by_space[i] = {} end

    for _, w in ipairs(windows) do
      local apps = by_space[w.space]
      -- Hidden/minimized windows aren't on screen; indices beyond MAX_SPACES are
      -- native fullscreen spaces or extra displays
      if apps and not w["is-minimized"] and not w["is-hidden"] then
        apps[w.app] = apps[w.app] or { name = w.app, pid = w.pid, window = w.id }
      end
    end

    for i = 1, MAX_SPACES do
      local list = {}
      for _, app in pairs(by_space[i]) do table.insert(list, app) end
      table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
      state[i].apps = list
      for _, app in ipairs(list) do resolve_bundle(app) end
      render(i)
    end
  end)
end

-- ── Events ────────────────────────────────────────────────────────────────────
-- force_space_refresh is a named event triggered by yabai signals for apps
-- (e.g. Claude Desktop) that don't emit space_windows_change reliably
sbar.add("event", "force_space_refresh")

local observer = sbar.add("item", "spaces.observer", { drawing = false, updates = true })
observer:subscribe({
  "space_windows_change", "force_space_refresh", "front_app_switched",
  "display_change", "system_woke", "forced",
}, function(_) refresh() end)

for i = 1, MAX_SPACES do
  numbers[i]:subscribe("space_change", function(env)
    state[i].selected = env.SELECTED == "true"
    paint(i)
  end)

  local function on_click(env, window)
    if env.BUTTON == "right" then
      if i > PERMANENT_SPACES then sbar.exec("yabai -m space --destroy " .. i) end
    elseif window then
      -- Clicking an app icon jumps straight to that app's window
      sbar.exec("yabai -m window --focus " .. window)
    elseif not state[i].selected then
      sbar.exec("yabai -m space --focus " .. i)
    end
  end

  local function hover(on)
    return function(_)
      if state[i].hovered == on then return end
      state[i].hovered = on
      paint(i)
    end
  end

  local parts = { numbers[i], overflow[i] }
  for j = 1, MAX_ICONS do table.insert(parts, app_slots[i][j]) end
  for _, part in ipairs(parts) do
    part:subscribe("mouse.entered", hover(true))
    part:subscribe({ "mouse.exited", "mouse.exited.global" }, hover(false))
  end

  numbers[i]:subscribe("mouse.clicked", function(env) on_click(env) end)
  overflow[i]:subscribe("mouse.clicked", function(env) on_click(env) end)
  for j = 1, MAX_ICONS do
    app_slots[i][j]:subscribe("mouse.clicked", function(env)
      local app = state[i].apps[j]
      on_click(env, app and app.window)
    end)
  end
end

refresh()
