local colors = require("colors")

-- macOS-style menu bar highlight: a soft capsule behind an item while hovered.
-- `is_pinned` (optional) keeps the highlight while e.g. its popup is open.
-- Instant on purpose: sketchybar 2.22 animations can segfault in bar_draw and
-- cost far more CPU than a single redraw.
return function(item, is_pinned)
  item:subscribe("mouse.entered", function(_)
    item:set({ background = { color = colors.highlight } })
  end)
  -- mouse.exited only: see the note on mouse.exited.global in items/spaces.lua
  item:subscribe("mouse.exited", function(_)
    if is_pinned and is_pinned() then return end
    item:set({ background = { color = colors.transparent } })
  end)
end
