-- the preset's value is in effect, the wheel changes the size, and a right click resets it
return {
  preset = "preset.lua",
  run = function(test)
    test.match(test.panel(1), { title = "Hello, OpenECS (32)" })
    -- a choice's default need not be its first choice
    test.match(test.setting("greeter.color"), "green", "the choice's default")

    local panel = test.rect(1)
    test.wheel(panel.x + 50, panel.y + 50, 1)
    test.match(test.panel(1), { title = "Hello, OpenECS (34)" }, "after the wheel")
    test.match(test.session().workspaces[1].windows[1].panels[1].state, { heard = { ["greeter.size"] = 1 } }, "ecs.settingChanged")

    -- a right click takes the user's size away, so the default applies again
    test.click(panel.x + 50, panel.y + 50, 3)
    test.match(test.panel(1), { title = "Hello, OpenECS (32)" }, "after the reset")

    -- a test changes a setting as the user's settings file does: its owner hears of it, and nil takes the user's value away again
    test.setSetting("greeter.name", "you")
    test.match(test.panel(1), { title = "Hello, you (32)" }, "the user's name")
    test.setSetting("greeter.name", nil)
    test.match(test.panel(1), { title = "Hello, OpenECS (32)" }, "the preset's name again")
  end,
}
