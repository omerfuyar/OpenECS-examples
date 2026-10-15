-- the model has a cube's 8 vertices and 12 triangles, and the panel draws every frame; the badge's texture comes from inside its .glb file, and its animation moves it
return {
  preset = "preset.lua",
  run = function(test)
    test.wait(0.3)
    local state = test.session().workspaces[1].windows[1].panels[1].state
    test.match({ state.vertices, state.triangles }, { 8, 12 }, "the cube")
    assert(state.drawn > 1, "frames drawn: " .. tostring(state.drawn))
    -- an image inside the model has no file, only its type
    test.match(state.texture, { mimeType = "image/png", width = 16, height = 16 }, "the texture inside the .glb")

    -- the badge's animation: a linear turn of 90 degrees a second, a step to the right at 2 seconds, and a cubic growth from 1 to 2 over 4 seconds
    local spin = state.spin
    test.match({ spin.name, spin.duration }, { "spin", 4 }, "the animation")
    local function near(a, b)
      return math.abs(a - b) < 0.001
    end
    test.match({ near(spin.early[1], 45), near(spin.early[2], 0), near(spin.late[1], -135), near(spin.late[2], 1) }, { true, true, true, true }, "the turn and the step")
    -- flat tangents give a smooth step: halfway in time is halfway in size
    test.match({ near(spin.middle[1], 180) or near(spin.middle[1], -180), near(spin.middle[3], 1.5) }, { true, true }, "the half turn and the growth")
  end,
}
