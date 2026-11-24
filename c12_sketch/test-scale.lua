-- at ecs.scale 1.5, the window buttons stay at the title bar's right end, where the pointer finds them, before and after the workspaces' menu
-- switches to a workspace with a longer name; the margins at the window's edges grow with the scale

local title = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "title.lua")

return {
  preset = "preset-large.lua",
  run = function(test)
    test.match(test.setting("ecs.scale"), 1.5, "the scale")
    title.checkMargin(test, 1, "with C")
    title.checkButtons(test, "with C")

    test.click(title.centre(title.parts(test).workspace.rect))
    test.key("Down")
    test.key("Return")
    test.match(title.parts(test).workspace.label, "Side by side \u{25BE}", "the second workspace, by the menu")
    title.checkMargin(test, 2, "with Side by side")
    title.checkButtons(test, "with Side by side")
  end,
}
