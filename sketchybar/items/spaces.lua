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
local EDGE_EMPTY = 7   -- same for a space without apps: a compact round pill
-- Each icon sits in a cell: the icon plus CELL_PAD on both sides
local CELL_PAD   = 2
local CELL       = ICON_SIZE + 2 * CELL_PAD
-- Icons sit 1 pt above the centre, leaving room below for the Dock-style dot
-- that marks the frontmost app
local ICON_LIFT  = 1
local DOT        = { string = "●", font = "SF Pro:Bold:4.0", y_offset = -9 }

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
      padding_left  = EDGE_EMPTY,
      padding_right = EDGE_EMPTY,
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

-- Bundle ids are kept on disk ("name<TAB>bundle id" lines): the icons are in
-- colour from the first frame, without one lsappinfo per app at every load
local CACHE_DIR  = os.getenv("HOME") .. "/.cache/sketchybar"
local CACHE_FILE = CACHE_DIR .. "/bundle_ids"

do
  local file = io.open(CACHE_FILE, "r")
  if file then
    for line in file:lines() do
      local name, bundle = line:match("^(.-)\t(.+)$")
      if name then bundle_ids[name] = bundle end
    end
    file:close()
  end
end

local function remember_bundle(name, bundle)
  local file = io.open(CACHE_FILE, "a")
  if not file then
    os.execute('mkdir -p "' .. CACHE_DIR .. '"')
    file = io.open(CACHE_FILE, "a")
  end
  if file then
    file:write(name, "\t", bundle, "\n")
    file:close()
  end
end

-- The frontmost app's icon gets a dot under it (see paint_dot)
local front_app = nil -- app name
local dotted    = nil -- the slot item currently showing the dot

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
  -- The slots are about to show other apps: the dot is worked out again
  if dotted then
    dotted:set({ label = { drawing = false } })
    dotted = nil
  end

  -- The space number only shows on its own display; the icons must follow it
  -- or every display would show the icons of every space
  local display = s.display or "all"
  for _, slot in ipairs(app_slots[i]) do slot:set({ display = display }) end
  if overflow[i] then overflow[i]:set({ display = display }) end

  numbers[i]:set({ icon = {
    padding_left  = (#apps > 0) and EDGE or EDGE_EMPTY,
    padding_right = (#apps > 0) and (5 - CELL_PAD) or EDGE_EMPTY,
  } })

  for j, slot in ipairs(app_slots[i]) do
    local app  = apps[j]
    if not app then
      slot:set({ drawing = false })
    else
      local last    = (j == shown) and extra == 0
      local bundle  = bundle_ids[app.name]
      local padding = last and EDGE or ICON_GAP
      if bundle then
        -- Image-only icons ignore their padding, so the gap comes from a fixed
        -- width; the cell already brings CELL_PAD on each side
        slot:set({
          drawing = true,
          width   = CELL + (last and (EDGE - CELL_PAD) or 0),
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

-- ── Front App Dot ─────────────────────────────────────────────────────────────
-- Marks the frontmost app's icon in the selected space with a small dot
-- under it, like the Dock. Only image slots: their fixed width keeps the dot
-- (a label pulled back under the icon) out of the layout.
local function paint_dot()
  local target
  for i = 1, MAX_SPACES do
    if state[i].selected then
      for j, app in ipairs(state[i].apps) do
        if app.name == front_app and bundle_ids[app.name] then target = app_slots[i][j] end
      end
    end
  end
  if target == dotted then return end
  if dotted then dotted:set({ label = { drawing = false } }) end
  if target then target:set({ label = { drawing = true } }) end
  dotted = target
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

-- Scrolling over the spaces moves to the previous / next one, like turning a
-- carousel. A gesture sends many events: one switch, then a short pause.
local scroll_paused = false

local function on_scroll(env)
  local delta = tonumber(env.INFO and env.INFO.delta) or 0
  if scroll_paused or delta == 0 then return end
  scroll_paused = true
  sbar.exec("yabai -m space --focus " .. (delta > 0 and "prev" or "next"))
  sbar.delay(0.25, function() scroll_paused = false end)
end

local function wire(i, part, on_clicked)
  part:subscribe("mouse.entered", hover(i, true))
  -- Not mouse.exited.global: it reaches every subscriber at once when the
  -- pointer leaves the bar, and dozens of them flood the Lua process until it
  -- deadlocks with sketchybar (each waiting on the other's mach message)
  part:subscribe("mouse.exited", hover(i, false))
  part:subscribe("mouse.clicked", on_clicked)
  part:subscribe("mouse.scrolled", on_scroll)
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
            drawing  = true,
            color    = colors.transparent,
            y_offset = ICON_LIFT,
            image    = { scale = ICON_SCALE, drawing = true,
                         padding_left = CELL_PAD, padding_right = CELL_PAD },
          },
        },
        -- The dot: drawn after the icon, pulled back to sit centred under it
        label = {
          drawing       = false,
          string        = DOT.string,
          font          = DOT.font,
          color         = colors.label,
          y_offset      = DOT.y_offset,
          padding_left  = -(CELL / 2 + 2),
          padding_right = 0,
        },
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
    if bundle_ids[app.name] then remember_bundle(app.name, bundle_ids[app.name]) end
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

local function apply(result)
  if type(result) ~= "table" or type(result.windows) ~= "table" then return end
  local windows = result.windows

  -- A native fullscreen app gets a space of its own, numbered like any other
  -- (e.g. 9 with a single display): hide that number, it isn't a desktop
  local is_fullscreen = {}
  for _, space in ipairs(result.spaces or {}) do
    is_fullscreen[space.index] = space["is-native-fullscreen"] == true
  end
  for i = 1, MAX_SPACES do
    local fullscreen = is_fullscreen[i] or false
    if state[i].fullscreen ~= fullscreen then
      state[i].fullscreen = fullscreen
      numbers[i]:set({ drawing = not fullscreen })
    end
  end

  local by_space   = {}
  local display_of = {} -- space index -> yabai display index (= sketchybar's)
  for i = 1, MAX_SPACES do by_space[i] = {} end

  local focused -- app of the focused window
  for _, w in ipairs(windows) do
    if w["has-focus"] then focused = w.app end
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

  if focused then front_app = focused end
  grow(function()
    for i = 1, MAX_SPACES do render(i) end
    paint_dot()
  end)
end

refresh = function()
  if in_flight and os.time() - in_flight < 10 then
    refresh_again = true
    return
  end
  in_flight, refresh_again = os.time(), false
  -- Windows and spaces in one JSON document, so one callback has both
  sbar.exec([[printf '{"windows":%s,"spaces":%s}' "$(yabai -m query --windows 2>/dev/null)" "$(yabai -m query --spaces 2>/dev/null)"]], function(result)
    in_flight = nil
    if refresh_again then return refresh() end
    apply(result)
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
    paint_dot()
  end)
  wire(i, numbers[i], function(env) on_click(i, env) end)
end

start_pad:subscribe("front_app_switched", function(env)
  front_app = env.INFO
  paint_dot()
end)

refresh()
