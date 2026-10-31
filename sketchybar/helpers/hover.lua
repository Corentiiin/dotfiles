local colors = require("colors")

-- macOS-style menu bar highlight: a soft capsule behind an item while hovered.
-- `is_pinned` (optional) keeps the highlight while e.g. its popup is open.
return function(item, is_pinned)
  item:subscribe("mouse.entered", function(_)
    sbar.animate("tanh", 8, function()
      item:set({ background = { color = colors.highlight } })
    end)
  end)
  item:subscribe({ "mouse.exited", "mouse.exited.global" }, function(_)
    if is_pinned and is_pinned() then return end
    sbar.animate("tanh", 8, function()
      item:set({ background = { color = colors.transparent } })
    end)
  end)
end
