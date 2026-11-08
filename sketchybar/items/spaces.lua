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
-- sketchybar gives every item a window on every display, even while hidden,
-- and creates, orders and destroys them all on each load and display change.
-- So icon slots and "+n" items are only created the first time a space needs
-- them (see grow), instead of 6 per space up front.
local numbers   = {} -- space index -> space item (the number)
local app_slots = {} -- space index -> { icon items }, created on demand
local overflow  = {} -- space index -> "+n" item, created on demand
local segments  = {} -- space index -> bracket (the segment capsule)
local state     = {} -- space index -> { selected, hovered, apps, signature }

-- Also receives the refresh events (see below), so no extra observer item
local start_pad = sbar.add("item", "spaces.start_pad", { width = 2, padding_left = 0, padding_right = 0 })

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

-- (Re)builds the segment of space i around its current parts: a bracket's
-- members are fixed when it is added
local function build_segment(i)
  if segments[i] then sbar.remove(segments[i].name) end
  local members = { numbers[i].name }
  for _, slot in ipairs(app_slots[i]) do table.insert(members, slot.name) end
  if overflow[i] then table.insert(members, overflow[i].name) end

  segments[i] = sbar.add("bracket", "segment." .. i, members, {
    background = {
      color         = colors.transparent,
      border_color  = colors.transparent,
      border_width  = 1,
      corner_radius = 12,
      height        = 24,
    },
  })
  state[i].painted_fill = nil -- the new bracket starts unpainted
end

for i = 1, MAX_SPACES do build_segment(i) end

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

  -- Every space item receives space_change and every refresh repaints all
  -- spaces: only touch the ones that actually change. No animation: fading a
  -- bracket redraws the whole bar every frame (~150 ms CPU per switch instead
  -- of ~12 ms) and sketchybar 2.22 animations can segfault in bar_draw.
  if s.painted_fill ~= fill then
    s.painted_fill = fill
    segments[i]:set({ background = { color = fill, border_color = rim } })
  end
  if s.painted_number ~= number_color then
    s.painted_number = number_color
    numbers[i]:set({ icon = { color = number_color } })
  end
end

-- ── App Icons ─────────────────────────────────────────────────────────────────
local bundle_ids = {} -- app name -> bundle id, or false when it can't be resolved
local pending    = {}

local function render(i)
  local s    = state[i]
  local apps = s.apps
  local shown = math.min(#apps, MAX_ICONS)
  local extra = #apps - shown

  local signature = { tostring(s.display) }
  for _, app in ipairs(apps) do table.insert(signature, app.name .. "=" .. tostring(bundle_ids[app.name])) end
  signature = table.concat(signature, ",")
  if signature == s.signature then return end
  s.signature = signature

  -- The space number only shows on its own display; the icons must follow it
  -- or every display would show the icons of every space
  local display = s.display or "all"
  for _, slot in ipairs(app_slots[i]) do slot:set({ display = display }) end
  if overflow[i] then overflow[i]:set({ display = display }) end

  numbers[i]:set({ icon = { padding_right = (#apps > 0) and 5 or EDGE } })

  for j, slot in ipairs(app_slots[i]) do
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

  if overflow[i] then
    overflow[i]:set({
      drawing = extra > 0,
      icon    = { string = "+" .. extra },
    })
  end

  paint(i)
end

-- ── Interaction ───────────────────────────────────────────────────────────────
local function on_click(i, env, window)
  if env.BUTTON == "right" then
    if i > PERMANENT_SPACES then sbar.exec("yabai -m space --destroy " .. i) end
  elseif window then
    -- Clicking an app icon jumps straight to that app's window
    sbar.exec("yabai -m window --focus " .. window)
  elseif not state[i].selected then
    sbar.exec("yabai -m space --focus " .. i)
  end
end

-- Moving between the parts of a segment (number, icons) sends exited then
-- entered: the highlight only drops if the pointer is still out a moment
-- later, so crossing icons doesn't repaint the segment twice
local function hover(i, on)
  return function(_)
    if state[i].hovered == on then return end
    state[i].hovered = on
    if on then return paint(i) end
    sbar.delay(0.03, function()
      if not state[i].hovered then paint(i) end
    end)
  end
end

local function wire(i, part, on_clicked)
  part:subscribe("mouse.entered", hover(i, true))
  -- Not mouse.exited.global: it reaches every subscriber at once when the
  -- pointer leaves the bar, and dozens of them flood the Lua process until it
  -- deadlocks with sketchybar (each waiting on the other's mach message)
  part:subscribe("mouse.exited", hover(i, false))
  part:subscribe("mouse.clicked", on_clicked)
end

-- ── Growing ───────────────────────────────────────────────────────────────────
-- Creates the icon slots and "+n" items the spaces now need. New items are
-- added hidden at the end of the bar, put in place after their space with a
-- single `sketchybar --move` call, then their segments are rebuilt around
-- them; `done` runs once they are in place.
local function grow(done)
  local moves, grown = {}, {}
  for i = 1, MAX_SPACES do
    local apps = state[i].apps
    local previous = (#app_slots[i] > 0) and app_slots[i][#app_slots[i]].name or numbers[i].name
    for j = #app_slots[i] + 1, math.min(#apps, MAX_ICONS) do
      local slot = sbar.add("item", "space." .. i .. ".app." .. j, {
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
      app_slots[i][j] = slot
      wire(i, slot, function(env)
        local app = state[i].apps[j]
        on_click(i, env, app and app.window)
      end)
      table.insert(moves, "--move " .. slot.name .. " after " .. previous)
      previous, grown[i] = slot.name, true
    end

    if #apps > MAX_ICONS and not overflow[i] then
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
      wire(i, overflow[i], function(env) on_click(i, env) end)
      table.insert(moves, "--move " .. overflow[i].name .. " after " .. previous)
      grown[i] = true
    end
  end

  if #moves == 0 then return done() end
  sbar.exec("sketchybar " .. table.concat(moves, " "), function(_)
    for i in pairs(grown) do
      build_segment(i)
      state[i].signature = nil -- render the new parts
    end
    done()
  end)
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

-- One yabai query refreshes every space (sbar.exec decodes the JSON into a table).
-- Events come in bursts (an app launching, a wake: dozens at once), so only one
-- query runs at a time: whatever arrives meanwhile is folded into a single
-- follow-up query, which also sees the latest state. A query stuck for more
-- than 10 s (yabai restarting) no longer blocks new ones.
local in_flight     = nil -- os.time() the running query started
local refresh_again = false

local refresh

local function apply(windows)
  if type(windows) ~= "table" then return end

  local by_space   = {}
  local display_of = {} -- space index -> yabai display index (= sketchybar's)
  for i = 1, MAX_SPACES do by_space[i] = {} end

  for _, w in ipairs(windows) do
    display_of[w.space] = w.display
    local apps = by_space[w.space]
    -- Some apps (Claude Desktop) only order their window out when it is
    -- closed: yabai drops it, but still lists it from the window server with
    -- no accessibility reference and not visible
    local closed = not w["has-ax-reference"] and not w["is-visible"]
    -- Hidden/minimized windows aren't on screen. A native fullscreen window
    -- sits on a space of its own, right after its display's spaces (e.g. 9):
    -- it has no number in the bar, so its icon would float there. Indices
    -- beyond MAX_SPACES are fullscreen spaces or extra displays.
    local fullscreen = w["is-native-fullscreen"]
    if apps and not closed and not fullscreen and not w["is-minimized"] and not w["is-hidden"] then
      apps[w.app] = apps[w.app] or { name = w.app, pid = w.pid, window = w.id }
    end
  end

  for i = 1, MAX_SPACES do
    local list = {}
    for _, app in pairs(by_space[i]) do table.insert(list, app) end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    state[i].apps = list
    state[i].display = display_of[i]
    for _, app in ipairs(list) do resolve_bundle(app) end
  end

  grow(function()
    for i = 1, MAX_SPACES do render(i) end
  end)
end

refresh = function()
  if in_flight and os.time() - in_flight < 10 then
    refresh_again = true
    return
  end
  in_flight, refresh_again = os.time(), false
  sbar.exec("yabai -m query --windows 2>/dev/null", function(windows)
    in_flight = nil
    if refresh_again then return refresh() end
    apply(windows)
  end)
end

-- ── Events ────────────────────────────────────────────────────────────────────
-- force_space_refresh is triggered by yabai signals once yabai's window list is
-- up to date (see yabairc), and by skhd after moving a window to another space.
-- No space_windows_change: it fires before yabai is up to date, once per space
-- on every space switch (when the icons don't change), and subscribing makes
-- sketchybar track every window on screen through the WindowServer for good.
sbar.add("event", "force_space_refresh")

start_pad:subscribe({
  -- No front_app_switched: focusing another app doesn't change which windows
  -- live on which space, and it would cost a yabai query on every cmd-tab
  "force_space_refresh", "display_change", "system_woke", "forced",
}, function(_) refresh() end)

for i = 1, MAX_SPACES do
  numbers[i]:subscribe("space_change", function(env)
    state[i].selected = env.SELECTED == "true"
    paint(i)
  end)
  wire(i, numbers[i], function(env) on_click(i, env) end)
end

refresh()
