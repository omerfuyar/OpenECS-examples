-- the model has a cube's 8 vertices and 12 triangles, and the panel draws every frame; the badge's texture comes from inside its .glb file
return {
  preset = "preset.lua",
  run = function(test)
    test.wait(0.3)
    local state = test.session().workspaces[1].windows[1].panels[1].state
    test.match({ state.vertices, state.triangles }, { 8, 12 }, "the cube")
    assert(state.drawn > 1, "frames drawn: " .. tostring(state.drawn))
    -- an image inside the model has no file, only its type
    test.match(state.texture, { mimeType = "image/png", width = 16, height = 16 }, "the texture inside the .glb")
  end,
}
