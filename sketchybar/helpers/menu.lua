local colors   = require("colors")
local settings = require("settings")

-- Builder for Apple-style menu bar popups (macOS 26 Control Center modules):
-- bold title, grey section headers, hairline separators, circle-icon rows,
-- toggles and "… Settings…" actions.
--
-- The content is rebuilt every time the menu opens: popup items keep the order
-- they were added in, and each build picks up the current light/dark appearance.
--
-- Geometry (sketchybar 2.22): a popup row is as tall as its item background, the
-- item padding offsets it inside the popup, and a text with a fixed width draws
-- its background from the text origin, ignoring its paddings.

local M = {}

M.WIDTH = 300
local INSET  = 6                   -- hover highlight inset from the popup edge
local TEXT   = 14                  -- text inset from the popup edge
local ROW    = M.WIDTH - 2 * INSET -- width of a full row
local CIRCLE = 26
-- macOS 26 toggle, drawn by assets/make_toggles.py (a glyph knob can't be
-- centered reliably: SF Symbols sit on the text baseline)
local TOGGLE_W = 54
local TOGGLE_IMAGE = os.getenv("CONFIG_DIR") .. "/assets/toggle_%s_%s.png"
local KNOB = "􀀁"

local function font(style, size)
  return { family = settings.font.text, style = settings.font.style_map[style], size = size }
end

local Menu = {}
Menu.__index = Menu

function M.new(parent)
  -- A tiny minimum cell lets every row define its own height
  parent:set({ popup = { align = "right", height = 4 } })
  return setmetatable({ parent = parent, parts = {}, palette = colors.menu.light, appearance = "light",
                        is_open = false, generation = 0 }, Menu)
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────
function Menu:clear()
  for _, item in ipairs(self.parts) do sbar.remove(item.name) end
  self.parts = {}
  -- Hover events can still arrive for removed rows: they check this to stay quiet
  self.generation = self.generation + 1
end

-- Subscribes a row handler that is ignored once the row has been removed
function Menu:on(item, event, handler)
  local generation = self.generation
  item:subscribe(event, function(env)
    if generation == self.generation then handler(env) end
  end)
end

function Menu:build()
  self:clear()
  self:spacer(6)
  self.builder(self)
  self:spacer(6)
  self.parent:set({ popup = { background = { color = self.palette.bg, border_color = self.palette.border } } })
end

-- Opens the menu with the current system appearance; `builder(menu)` adds the rows
function Menu:open(builder)
  if self.is_open then return end
  self.is_open = true
  self.builder = builder
  sbar.exec("defaults read -g AppleInterfaceStyle 2>/dev/null", function(result)
    if not self.is_open then return end
    self.appearance = tostring(result or ""):find("Dark") and "dark" or "light"
    self.palette = colors.menu[self.appearance]
    self:build()
    self.parent:set({ popup = { drawing = true } })
  end)
end

-- Rebuilds an open menu after its state changed (e.g. another device selected)
function Menu:refresh()
  if self.is_open then self:build() end
end

function Menu:close()
  if not self.is_open then return end
  self.is_open = false
  self.parent:set({ popup = { drawing = false } })
  self:clear()
end

-- ── Rows ──────────────────────────────────────────────────────────────────────
function Menu:add(props, kind, slider_width)
  props.position = "popup." .. self.parent.name
  local item = (kind == "slider") and sbar.add("slider", slider_width, props) or sbar.add("item", props)
  table.insert(self.parts, item)
  return item
end

-- Transparent row used for vertical breathing room
function Menu:spacer(height)
  return self:add({
    width = ROW, padding_left = INSET, padding_right = INSET,
    icon = { drawing = false }, label = { drawing = false },
    background = { drawing = true, color = colors.transparent, height = height },
  })
end

-- Bold module title, optionally with an Apple toggle on the right
function Menu:title(text, toggle)
  local p = self.palette
  local props = {
    width = ROW, padding_left = INSET, padding_right = INSET,
    icon = {
      string        = text,
      font          = font("Bold", 13.0),
      color         = p.label,
      padding_left  = TEXT - INSET,
      padding_right = 0,
    },
    label      = { drawing = false },
    background = { drawing = true, color = colors.transparent, height = 32 },
  }
  if toggle then
    -- Fixed-width title pushes the toggle against the right text inset
    props.icon.width = ROW - TOGGLE_W - (TEXT - INSET)
    props.label = {
      drawing       = true,
      string        = "",
      width         = TOGGLE_W,
      padding_left  = 0,
      padding_right = 0,
      background = {
        drawing = true,
        color   = colors.transparent,
        image   = {
          string = TOGGLE_IMAGE:format(toggle.on and "on" or "off", self.appearance),
          scale  = 0.5,
        },
      },
    }
  end
  local item = self:add(props)
  if toggle and toggle.on_click then self:on(item, "mouse.clicked", toggle.on_click) end
  return item
end

-- Grey section header ("Output", "Known Network")
function Menu:header(text)
  return self:add({
    width = ROW, padding_left = INSET, padding_right = INSET,
    icon  = { drawing = false },
    label = {
      string       = text,
      font         = font("Semibold", 12.0),
      color        = self.palette.secondary,
      padding_left = TEXT - INSET,
    },
    background = { drawing = true, color = colors.transparent, height = 24 },
  })
end

-- Grey one-line information ("Power Source: Battery")
function Menu:info(text)
  return self:add({
    width = ROW, padding_left = INSET, padding_right = INSET,
    icon  = { drawing = false },
    label = {
      string       = text,
      font         = font("Regular", 13.0),
      color        = self.palette.secondary,
      padding_left = TEXT - INSET,
    },
    background = { drawing = true, color = colors.transparent, height = 24 },
  })
end

-- Key/value detail line, like the option-click details of the Wi-Fi menu:
-- indented under the name of the circle row above it (a fixed width counts
-- the left padding too)
function Menu:detail(key, value)
  local indent = TEXT - INSET + CIRCLE + 8
  return self:add({
    width = ROW, padding_left = INSET, padding_right = INSET,
    icon = {
      string       = key,
      font         = font("Regular", 12.0),
      color        = self.palette.secondary,
      width        = indent + 80,
      padding_left = indent,
    },
    label = {
      string = value,
      font   = font("Regular", 12.0),
      color  = self.palette.label,
    },
    background = { drawing = true, color = colors.transparent, height = 20 },
  })
end

-- Hairline separator aligned with the text
function Menu:separator()
  return self:add({
    width = M.WIDTH - 2 * TEXT, padding_left = TEXT, padding_right = TEXT,
    icon  = { drawing = false },
    label = {
      string     = "",
      width      = M.WIDTH - 2 * TEXT,
      background = { drawing = true, color = self.palette.separator, height = 1 },
    },
    background = { drawing = true, color = colors.transparent, height = 11 },
  })
end

-- Row with a round icon; the active one is filled with the accent color
function Menu:circle_row(text, glyph, active, callback)
  local p = self.palette
  local circle = active and p.accent or p.circle
  local item = self:add({
    width = ROW - (TEXT - INSET), padding_left = TEXT, padding_right = INSET,
    icon = {
      string        = glyph,
      font          = { family = settings.font.text, style = settings.font.style_map["Regular"], size = 12.0 },
      color         = active and 0xffffffff or p.label,
      width         = CIRCLE,
      align         = "center",
      padding_left  = 0,
      padding_right = 0,
      background    = { drawing = true, color = circle, height = CIRCLE, corner_radius = CIRCLE / 2 },
    },
    label = {
      string       = text,
      font         = font("Regular", 13.0),
      color        = p.label,
      padding_left = 8,
    },
    background = { drawing = true, color = colors.transparent, height = 32 },
  })

  if not active then
    self:on(item, "mouse.entered", function(_)
      item:set({ icon = { background = { color = p.circle_hover } } })
    end)
    self:on(item, "mouse.exited", function(_)
      item:set({ icon = { background = { color = p.circle } } })
    end)
  end
  if callback then self:on(item, "mouse.clicked", callback) end
  return item
end

-- Full-width action row ("Sound Settings…") with the menu hover highlight
function Menu:action(text, callback)
  local p = self.palette
  local item = self:add({
    width = ROW, padding_left = INSET, padding_right = INSET,
    icon  = { drawing = false },
    label = {
      string       = text,
      font         = font("Regular", 13.0),
      color        = p.label,
      padding_left = TEXT - INSET,
    },
    background = { drawing = true, color = colors.transparent, height = 24, corner_radius = 8 },
  })
  self:on(item, "mouse.entered", function(_) item:set({ background = { color = p.hover } }) end)
  self:on(item, "mouse.exited", function(_) item:set({ background = { color = colors.transparent } }) end)
  if callback then self:on(item, "mouse.clicked", callback) end
  return item
end

-- Accent-filled slider spanning the text column
function Menu:slider(percentage, click_script)
  local width = M.WIDTH - 2 * TEXT
  return self:add({
    padding_left  = TEXT,
    padding_right = TEXT,
    -- Empty icon/label still carry default paddings that would shift the track
    icon  = { drawing = false },
    label = { drawing = false },
    slider = {
      percentage      = percentage,
      highlight_color = self.palette.accent,
      background = { height = 5, corner_radius = 2.5, color = self.palette.track },
      knob = {
        string  = KNOB,
        font    = { family = settings.font.text, style = settings.font.style_map["Regular"], size = 18.0 },
        color   = 0xffffffff,
        shadow  = { drawing = true, color = 0x40000000, angle = 270, distance = 1 },
        drawing = true,
      },
    },
    background   = { drawing = true, color = colors.transparent, height = 30 },
    click_script = click_script,
  }, "slider", width)
end

return M
