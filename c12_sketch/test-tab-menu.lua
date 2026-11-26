-- a right click on a tab and a right click on the rest of the row open one menu, the panel's, which acts on the panel and on
-- its group: close, close the group, the submenu Tabs, and the rest; a tab row has no button for it

-- the open menu draws no text in the padding at its right: each entry's keys end an entry's padding before the menu's own, as its
-- label starts at its left, so the widest keys do not touch the edge. The menu's background gets a colour that nothing else has, and
-- no transparency, so a pixel of text differs from it
local function checkRightEdge(test, message)
  local rect = test.menu().rect
  local scale = test.setting("ecs.scale") or 1
  test.setSetting("ecs.colorOverlay", "#FF00FF")
  local background = {}

  for _, setting in ipairs({ "ecs.colorOverlay", "ecs.colorSelected", "ecs.colorFrame" }) do
    background[test.setting(setting)] = true
  end

  local right = rect.x + rect.width
  local drawn = {}

  for _, column in ipairs({ right - math.floor(8 * scale), right - math.floor(11 * scale) }) do
    for row = rect.y + 5, rect.y + rect.height - 6 do
      if not background[test.pixel(column, row)] then
        drawn[#drawn + 1] = ("text at %d, %d"):format(column, row)
        break
      end
    end
  end

  test.setSetting("ecs.colorOverlay", nil)
  test.match(drawn, {}, message)
end

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

    -- a right click on the C clock's tab opens its menu, with its first entry chosen; each entry shows the keys that run it after the
    -- prefix. Its submenu Tabs marks the shown tab, and its entry of the Lua clock shows that clock
    test.click(clock.x + 40, y, 3)
    test.match(test.menu()[1], { label = "Close", keys = "Alt+W, X", enabled = true, chosen = true }, "the menu's first entry")
    -- the menu opens at the click, raised to keep inside the window
    test.match({ test.menu().rect.x, test.menu().window }, { clock.x + 40, 1 }, "the menu opens at the click")
    checkRightEdge(test, "the menu is as wide as its widest entry's label and keys")
    test.choose("Tabs")
    test.match(test.menu(), { { keys = "\u{2022}", chosen = true }, { label = "Lua clock", chosen = false } }, "the submenu Tabs")
    test.choose("Lua clock")
    test.match(test.menu(), nil, "no menu after Return")
    test.match(shown(), 2, "the Lua clock shown from the tab's Tabs")

    -- a right click on the rest of the row opens the same menu, for the shown panel: its first entry closes the Lua clock
    test.click(clock.x + clock.width - 60, y, 3)
    test.key("Return")
    test.match(types(test), { "sketch_c.canvas", "sketch_lua.canvas", "sketch_c.clock" }, "the Lua clock closed from the row's right click")
  end,
}
