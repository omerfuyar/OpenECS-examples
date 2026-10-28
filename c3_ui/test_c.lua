-- the controls in C, on workspace 2, pass the checks of the controls in Lua: ui's macros describe the same elements, and take what each one got at
-- the next draw

local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset.lua",
  run = function(test)
    test.call("ecs.workspace.switch2")
    checks(test, 2, "Controls in C")
  end,
}
