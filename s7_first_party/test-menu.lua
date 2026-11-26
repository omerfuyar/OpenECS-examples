-- the title bar's menu Tools holds what the standard plugins add, by mouse and by keys

-- the types of the panels of the main window
local function types(test)
  local found = {}

  for _, panel in ipairs(test.panels()) do
    found[#found + 1] = panel.type
  end

  return found
end

-- chooses the entry with a label in the open menu: Down moves the choice until it is there, so an entry added before it changes nothing
local function choose(test, label)
  for _ = 1, #test.menu() do
    for _, entry in ipairs(test.menu()) do
      if entry.chosen and entry.label == label then
        return
      end
    end

    test.key("Down")
  end

  error(("the menu has no entry '%s'"):format(label), 2)
end

return {
  preset = "preset.lua",
  run = function(test)
    test.match(types(test), { "shapes.square" }, "the square alone")

    -- the title bar's menu Tools holds what the standard plugins add, by their labels: the launcher, the panel list, then the settings window.
    -- A click on its part opens it with its first entry chosen
    local tools
    for _, part in ipairs(test.titleBar()) do
      tools = part.label == "Tools" and part.rect or tools
    end
    test.click(tools.x + tools.width / 2, tools.y + tools.height / 2)
    test.match(test.menu(), { { label = "Open the launcher", chosen = true }, { label = "Open the panel list" }, { label = "Open the settings" } },
      "the menu Tools")
    choose(test, "Open the settings")
    test.key("Return")
    test.match(types(test), { "shapes.square", "settings.window" }, "the settings window opened from the menu Tools")

    -- ecs.app.menu opens the title bar's first menu, File, with keys; Right goes to the next menu, Window, then Tools
    test.call("ecs.app.menu")
    test.key("Right")
    test.key("Right")
    choose(test, "Open the panel list")
    test.key("Return")
    test.match(types(test), { "shapes.square", "settings.window", "panels.list" }, "the panel list opened from the menu Tools")
  end,
}
