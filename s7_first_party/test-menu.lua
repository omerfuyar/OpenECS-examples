-- a right click on the title bar opens the tool's menu, whose submenu Tools holds what the standard plugins add: the settings window first

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

    -- the title bar is at the top of the window, after its menus; a menu opens with its first entry chosen: save and open the session,
    -- then Tools, whose submenu Right opens. Its entries go by their labels: the launcher, the panel list, then the settings window
    local bar = test.titleBar()
    local last = bar[#bar].rect
    test.click(last.x + last.width + 20, 10, 3)
    test.key("Down")
    test.key("Down")
    test.key("Right")
    test.key("Down")
    test.key("Down")
    test.key("Return")
    test.match(types(test), { "shapes.square", "settings.window" }, "the settings window opened from the tool's menu")

    -- ecs.app.menu opens the same menu with keys; in Tools, the panel list is the second
    test.call("ecs.app.menu")
    test.key("Down")
    test.key("Down")
    test.key("Right")
    test.key("Down")
    test.key("Return")
    test.match(types(test), { "shapes.square", "settings.window", "panels.list" }, "the panel list opened from the tool's menu")
  end,
}
