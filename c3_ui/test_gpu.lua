-- the controls in Lua and in C with the setting ui.gpu on: both panels draw on the GPU, and pass the checks they pass on pixels, which read
-- the same colours inside their elements

local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset_gpu.lua",
  run = function(test)
    local function surface(number)
      return test.session().workspaces[number].windows[1].panels[1].state.surface
    end

    test.match(surface(1), "gpu", "the panel in Lua is on the GPU")
    checks(test, 1, "Controls")

    test.call("ecs.workspace.switch2")
    test.wait(0.2)
    test.match(surface(2), "gpu", "the panel in C is on the GPU")
    checks(test, 2, "Controls in C")
  end,
}
