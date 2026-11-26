-- the checks of the sample, which the sample in Lua and the one in C pass alike: it marks the pointer while a colour from the palette is over it,
-- from the core's dragOver until its dragLeave, and takes the colour dropped on it
return function(test, name)
  local palette, sample = test.rect(1), test.rect(2)
  local x, y = sample.x + 50, sample.y + 50

  local function marked()
    return test.pixel(x, y) ~= test.pixel(x + 30, y)
  end

  local function color()
    return test.session().workspaces[1].windows[1][2].panels[1].state.color
  end

  -- the third swatch, held over the sample: the sample marks the pointer
  test.press(palette.x + 2 * 48 + 10, palette.y + 10)
  test.move(sample.x + 20, y)
  test.move(x, y)
  test.match(marked(), true, name .. " marks the pointer while a colour is over it")

  -- back over the palette, the colour left the sample
  test.move(palette.x + 10, palette.y + 60)
  test.match(marked(), false, name .. " drops its mark when the colour leaves")

  -- Escape cancels the drag: the mark goes, and the release drops nothing
  test.move(x, y)
  test.key("Escape")
  test.match(marked(), false, name .. " drops its mark when the drag is cancelled")
  test.release(x, y)
  test.match(color(), "#4C566A", name .. " keeps its colour after a cancelled drag")

  -- a drop colours the sample, and its mark goes
  test.press(palette.x + 2 * 48 + 10, palette.y + 10)
  test.move(sample.x + 20, y)
  test.move(x, y)
  test.release(x, y)
  test.match(marked(), false, name .. " drops its mark after the drop")
  test.match(color(), "#EBCB8B", name .. " takes the dropped colour")
end
