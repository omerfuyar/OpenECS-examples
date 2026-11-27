-- the controls in Lua and in C with the setting ui.gpu off: both panels draw into pixels, and pass the checks they pass on the GPU, which
-- read the same colours inside their elements

local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset_pixels.lua",
  run = function(test)
    local function surface(number)
      return test.session().workspaces[number].windows[1].panels[1].state.surface
    end

    test.match(surface(1), "pixels", "the panel in Lua draws into pixels")
    checks(test, 1, "Controls")

    test.call("ecs.workspace.switch2")
    test.wait(0.2)
    test.match(surface(2), "pixels", "the panel in C draws into pixels")
    checks(test, 2, "Controls in C")
  end,
}
