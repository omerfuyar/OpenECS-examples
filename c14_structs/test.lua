-- clicks add points, whose path the title measures with geometry's vectors in C; the session saves them as plain tables
return {
  preset = "preset.lua",
  run = function(test)
    local panel = test.rect(1)
    test.click(panel.x + 10, panel.y + 10)
    test.click(panel.x + 40, panel.y + 50)
    test.match(test.panel(1), { title = "Path (50)" }, "a 30 by 40 step")

    -- a click on the last point adds nothing: == runs geometry's equal
    test.click(panel.x + 40, panel.y + 50)
    test.click(panel.x + 40, panel.y + 60)
    test.match(test.panel(1), { title = "Path (60)" }, "the second step")

    local state = test.session().workspaces[1].windows[1].panels[1].state
    test.match(state, { points = { { x = 10, y = 10 }, { x = 40, y = 50 }, { x = 40, y = 60 } } }, "the saved points")

    -- a right click clears the path
    test.click(panel.x + 10, panel.y + 10, 3)
    test.match(test.panel(1), { title = "Path (0)" }, "the cleared path")
  end,
}
