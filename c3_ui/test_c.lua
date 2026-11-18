-- the controls in C, on workspace 2, pass the checks of the controls in Lua: ui's macros describe the same elements, and take what each one got at
-- the next draw

local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset.lua",
  run = function(test)
    test.call("ecs.workspace.switch2")
    test.wait(0.2)

    -- the same elements have the same places in both panels, before anything is clicked
    local workspaces = test.session().workspaces
    test.match(workspaces[2].windows[1].panels[1].state.rects, workspaces[1].windows[1].panels[1].state.rects, "the elements' places in C and in Lua")
    checks(test, 2, "Controls in C")
  end,
}
