-- each GPU panel, the one in Lua and the one in C, shows its four tiles on the background, and keeps showing them after it pops out into a window of its own;
-- the panel in Lua also shows its title, which gpu draws as text; the shapes panels, in Lua and in C, show gpu's shapes, clips and styled text

return {
  preset = "preset.lua",
  run = function(test)
    assert(test.panel(1).fault == nil, test.panel(1).fault)

    -- the colours at the middle of each tile, and in a corner of the panel
    local function check(id, message)
      local panel = test.rect(id)
      local side = math.floor(math.min(panel.width, panel.height) / 2)
      local left = panel.x + math.floor((panel.width - side) / 2)
      local top = panel.y + math.floor((panel.height - side) / 2)
      local a, b = side / 4, side * 3 / 4

      test.match(test.pixel(left + a, top + a), "#BF616A", message .. ": the top-left tile")
      test.match(test.pixel(left + b, top + a), "#A3BE8C", message .. ": the top-right tile")
      test.match(test.pixel(left + a, top + b), "#EBCB8B", message .. ": the bottom-left tile")
      test.match(test.pixel(left + b, top + b), "#5E81AC", message .. ": the bottom-right tile")
      -- the group's corners are rounded, so the background is read a little inside the bottom-left corner
      test.match(test.pixel(panel.x + 8, panel.y + panel.height - 8), "#1B2A4A", message .. ": the background")
    end

    check(1, "the panel in Lua")

    -- the title's letters cover part of a line through them, and the background shows between them
    local panel = test.rect(1)
    local letters, gaps = 0, 0

    for x = panel.x + 8, panel.x + 100 do
      if test.pixel(x, panel.y + 16) == "#1B2A4A" then gaps = gaps + 1 else letters = letters + 1 end
    end

    assert(letters > 10 and gaps > 10, ("the title of the panel in Lua: %d pixels of letters and %d of background"):format(letters, gaps))

    -- gpu's shapes, in Lua and in C: inside each shape its colour, and the background where a shape leaves it, inside a rounded corner,
    -- inside a ring or an outline, and outside a clip
    local BACKGROUND = "#1B2A4A"

    local function shapes(id, message)
      local panel = test.rect(id)
      assert(test.panel(id).fault == nil, test.panel(id).fault)
      -- the tests' windows have a scale of 1, so layout units are pixels
      local function at(x, y) return test.pixel(panel.x + x, panel.y + y) end
      local function is(x, y, color, what) test.match(at(x, y), color, ("%s: %s"):format(message, what)) end

      is(40, 30, "#BF616A", "the rounded rectangle's middle")
      is(11, 11, BACKGROUND, "outside the rounded rectangle's corner")
      is(110, 12, "#A3BE8C", "the rounded edge")
      is(110, 30, BACKGROUND, "inside the rounded edge")
      is(40, 80, "#EBCB8B", "the circle's middle")
      is(23, 63, BACKGROUND, "outside the circle")
      is(110, 62, "#5E81AC", "the ring")
      is(110, 80, BACKGROUND, "inside the ring")
      is(151, 30, "#88C0D0", "the outline")
      is(170, 30, BACKGROUND, "inside the outline")
      is(160, 85, "#B48EAD", "inside the clip")
      is(180, 85, BACKGROUND, "outside the clip")
      is(160, 65, "#D08770", "inside both clips")
      is(180, 65, BACKGROUND, "inside the inner clip, outside the outer one")
      is(100, 140, BACKGROUND, "below the clips")

      -- the panel in Lua draws a pipeline over the whole surface inside a clip, which keeps it to the clip
      if id == 3 then
        -- the shader writes 128 of 255 exactly, which every driver keeps; a half rounds either way
        is(215, 30, "#008080", "the pipeline, inside its clip")
        is(240, 30, BACKGROUND, "the pipeline, right of its clip")
        is(215, 60, BACKGROUND, "the pipeline, below its clip")
      end

      -- the bold text covers more pixels than the same text in the font itself
      local function covered(top)
        local count = 0
        for y = top, top + 18 do
          for x = 10, 70 do
            if at(x, y) ~= BACKGROUND then count = count + 1 end
          end
        end
        return count
      end

      local regular, bold = covered(110), covered(130)
      assert(regular > 20 and bold > regular * 1.15, ("%s: the bold text covers %d pixels, the regular %d"):format(message, bold, regular))
    end

    shapes(3, "the shapes in Lua")
    shapes(4, "the shapes in C")

    -- the same texture shows in the pop-out window, whose renderer is another one on the same device; the other tab shows in the main window
    test.call("ecs.layout.popOut")
    test.match(test.rect(1).window, 2, "the pop-out window")
    test.window(2)
    check(1, "the panel in Lua, in its own window")
    test.window(1)
    check(2, "the panel in C")
    assert(test.panel(2).fault == nil, test.panel(2).fault)
  end,
}
