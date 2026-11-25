-- a right click on a tab and a right click on the rest of the row open one menu, the panel's, which acts on the panel and on
-- its group: close, close the group, the submenu Tabs, and the rest; a tab row has no button for it

-- the types of the panels of the third workspace, the clocks' group last
local function types(test)
  local found = {}

  for _, panel in ipairs(test.panels()) do
    if panel.workspace == 3 then
      found[#found + 1] = panel.type
    end
  end

  return found
end

return {
  preset = "preset.lua",
  run = function(test)
    test.call("ecs.workspace.switch3")

    -- the clocks' group shows the C clock; its tab row is above its rectangle
    local clock = test.rect(7)
    local y = clock.y - 12
    local function shown()
      return test.session().workspaces[3].windows[1][2].shown
    end

    -- a click at the row's end opens no menu, so Return reaches no entry and both clocks stay
    test.click(clock.x + clock.width - 12, y)
    test.key("Return")
    test.match(#types(test), 4, "a click at the row's end opens no menu")

    -- a right click on the C clock's tab opens its menu: close, close group, maximize, pop out, lock, then Tabs, whose second
    -- entry shows the Lua clock
    test.click(clock.x + 40, y, 3)
    for _ = 1, 5 do
      test.key("Down")
    end
    test.key("Right")
    test.key("Down")
    test.key("Return")
    test.match(shown(), 2, "the Lua clock shown from the tab's Tabs")

    -- a right click on the rest of the row opens the same menu, for the shown panel: its first entry closes the Lua clock
    test.click(clock.x + clock.width - 60, y, 3)
    test.key("Return")
    test.match(types(test), { "sketch_c.canvas", "sketch_lua.canvas", "sketch_c.clock" }, "the Lua clock closed from the row's right click")
  end,
}
