-- the wheel over a tab row shows the next or previous tab, stops at the ends, and moves the focus with the tab when the group has it

return {
  preset = "preset.lua",
  run = function(test)
    test.call("ecs.workspace.switch3")

    -- the clocks' group shows the C clock; its tab row is above its rectangle
    local clock = test.rect(7)
    local x, y = clock.x + 20, clock.y - 12
    local function shown()
      return test.session().workspaces[3].windows[1][2].shown
    end

    -- the canvas has the focus, so the group's tab changes and the focus stays
    test.wheel(x, y, -1)
    test.match({ shown(), test.session().workspaces[3].focus }, { 2, 5 }, "the next tab")
    test.wheel(x, y, -1)
    test.match(shown(), 2, "the last tab stays")
    test.wheel(x, y, 1)
    test.match(shown(), 1, "the previous tab")
    test.wheel(x, y, 1)
    test.match(shown(), 1, "the first tab stays")

    -- with the focus in the group, the focus moves with the tab
    test.click(clock.x + 100, clock.y + 100)
    test.wheel(x, y, -1)
    test.match({ shown(), test.session().workspaces[3].focus }, { 2, 8 }, "the focus moves with the tab")
  end,
}
