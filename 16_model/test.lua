-- the model has a cube's 8 vertices and 12 triangles, and the panel draws every frame
return {
  preset = "preset.lua",
  run = function(test)
    test.wait(0.3)
    local state = test.session().workspaces[1].windows[1].panels[1].state
    test.match({ state.vertices, state.triangles }, { 8, 12 }, "the cube")
    assert(state.drawn > 1, "frames drawn: " .. tostring(state.drawn))
  end,
}
