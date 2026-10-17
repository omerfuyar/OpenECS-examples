-- the torus is read from its glTF file and drawn every frame on the GPU with its own shaders: a corner shows the background, and the ring shows the
-- material's colour, lit; a drag turns it, and the wheel moves it nearer
return {
  preset = "preset.lua",
  run = function(test)
    test.wait(0.3)
    assert(test.panel(1).fault == nil, test.panel(1).fault)

    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    test.match({ state().vertices, state().triangles }, { 561, 1024 }, "the torus")
    assert(state().drawn > 1, "frames drawn: " .. tostring(state().drawn))
    test.match(state().pipeline, true, "the pipeline, from the shaders")
    assert(state().labelParts >= 1, "the label's parts: " .. tostring(state().labelParts))

    -- a pixel's colour, as red, green and blue
    local function rgb(x, y)
      local text = test.pixel(x, y)
      return tonumber(text:sub(2, 3), 16), tonumber(text:sub(4, 5), 16), tonumber(text:sub(6, 7), 16)
    end

    local panel = test.rect(1)
    local cx, cy = panel.x + panel.width / 2, panel.y + panel.height / 2
    test.match(test.pixel(panel.x + 4, panel.y + 4), "#101418", "the background in a corner")

    -- some pixel between the hole and the edge of the ring has the teal of the material: more green and blue than red
    local found = false

    for step = 1, 40 do
      local r, g, b = rgb(cx + step * panel.height / 100, cy)

      if g > r + 30 and b > r + 30 then
        found = true
        break
      end
    end

    test.match(found, true, "the lit ring")

    -- dragging turns the model by the distance moved, and the wheel brings it nearer
    local turn = state().turn
    test.drag(cx, cy, cx + 100, cy)
    test.match(state().turn > turn + 0.9, true, "the drag turns it")
    local distance = state().distance
    test.wheel(cx, cy, 2)
    test.match(state().distance < distance, true, "the wheel brings it nearer")
  end,
}
