-- closing panels changes the layout, and resetting it gives back the preset's layout of the current workspace

-- the types of the panels in a layout tree, in order
local function types(node, list)
  list = list or {}

  for _, panel in ipairs(node.panels or {}) do
    list[#list + 1] = panel.type
  end

  for _, child in ipairs(node) do
    types(child, list)
  end

  return list
end

local function shown(test)
  return types(test.session().workspaces[1].windows[1])
end

return {
  preset = "preset.lua",
  run = function(test)
    test.match(shown(test), { "sketch_c.canvas", "sketch_c.clock" }, "the preset's layout")

    -- the canvas has the focus at start; its group closes
    test.call("ecs.layout.closeGroup")
    test.match(shown(test), { "sketch_c.clock" }, "after the canvas's group closed")

    -- the core's settings file binds the reset to Alt+W, then Shift+R
    test.key("Alt+W")
    test.key("Shift+R")
    test.match(shown(test), { "sketch_c.canvas", "sketch_c.clock" }, "after the reset")
  end,
}
