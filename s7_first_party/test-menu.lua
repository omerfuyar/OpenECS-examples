-- a right click on the title bar opens the tool's menu, whose entries the core's settings file names: the settings window first

-- the types of the panels of the main window
local function types(test)
  local found = {}

  for _, panel in ipairs(test.panels()) do
    found[#found + 1] = panel.type
  end

  return found
end

return {
  preset = "preset.lua",
  run = function(test)
    test.match(types(test), { "shapes.square" }, "the square alone")

    -- the title bar is at the top of the window, left of its buttons; a menu opens with its first entry chosen, and Return runs it
    test.click(100, 10, 3)
    test.key("Return")
    test.match(types(test), { "shapes.square", "settings.window" }, "the settings window opened from the tool's menu")

    -- ecs.app.menu opens the same menu with keys; Down chooses the second entry, the panel list
    test.call("ecs.app.menu")
    test.key("Down")
    test.key("Return")
    test.match(types(test), { "shapes.square", "settings.window", "panels.list" }, "the panel list opened from the tool's menu")
  end,
}
