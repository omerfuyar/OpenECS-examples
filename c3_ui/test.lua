-- the controls in Lua, on workspace 1: each control changes the panel's state, as the checks that the C plugin passes too say

local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset.lua",
  run = function(test)
    checks(test, 1, "Controls")

    -- ui's inspector outlines every element, and names the one under the pointer: the innermost element there, with its id
    local panel = test.rect(1)
    local state = test.session().workspaces[1].windows[1].panels[1].state
    local rect = state.rects.button
    test.call("ui.inspect")
    test.move(panel.x + rect.x + rect.width / 2, panel.y + rect.y + rect.height / 2)
    test.wait(0.2)
    state = test.session().workspaces[1].windows[1].panels[1].state
    test.match(state.inspected, { type = "button", id = "button" }, "the inspected element")
    test.call("ui.inspect")
  end,
}
