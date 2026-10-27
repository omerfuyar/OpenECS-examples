-- each GPU panel, the one in Lua and the one in C, shows its four tiles on the background, and keeps showing them after it pops out into a window of its own;
-- the panel in Lua also shows its title, which gpu draws as text

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
      test.match(test.pixel(panel.x + 2, panel.y + 2), "#1B2A4A", message .. ": the background")
    end

    check(1, "the panel in Lua")

    -- the title's letters cover part of a line through them, and the background shows between them
    local panel = test.rect(1)
    local letters, gaps = 0, 0

    for x = panel.x + 8, panel.x + 100 do
      if test.pixel(x, panel.y + 16) == "#1B2A4A" then gaps = gaps + 1 else letters = letters + 1 end
    end

    assert(letters > 10 and gaps > 10, ("the title of the panel in Lua: %d pixels of letters and %d of background"):format(letters, gaps))

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
