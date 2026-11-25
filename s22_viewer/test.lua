-- the viewer shows each kind of file: its panel takes the file's name, and keeps its path as its state
return {
  preset = "preset.lua",
  run = function(test)
    local function viewer()
      for _, panel in ipairs(test.panels()) do
        if panel.type == "viewer.file" then
          return test.panel(panel.id)
        end
      end
    end

    test.wait(0.2)
    local shown = viewer()
    test.match(shown, { title = "halves.png" }, "the image")
    assert(shown.state.path:match("gallery[/\\]halves%.png$"), "the panel keeps the file's path: " .. tostring(shown.state.path))
    -- an image fills the panel: a small one by a whole number of times, here 16, so its red and blue halves are 64 pixels wide
    local rect
    for _, panel in ipairs(test.panels()) do
      rect = panel.type == "viewer.file" and test.rect(panel.id) or rect
    end
    test.match({ test.pixel(rect.x + 30, rect.y + 90), test.pixel(rect.x + 110, rect.y + 90) }, { "#E06C75", "#61AFEF" }, "the image is drawn")

    test.call("gallery.next")
    test.match(viewer(), { title = "click.wav" }, "the sound")
    test.call("gallery.next")
    test.match(viewer(), { title = "init.lua" }, "the text")

    -- each line of a text starts with its number, dim and grey, in a column at the left, and the rows that the file's first line, a long
    -- comment, wraps into show a dim mark there instead. The comment's colour is not grey: its first row finds where the text starts
    local function channels(color)
      return tonumber(color:sub(2, 3), 16), tonumber(color:sub(4, 5), 16), tonumber(color:sub(6, 7), 16)
    end
    local function grey(x, y)
      local r, g, b = channels(test.pixel(x, y))
      return r == g and g == b, r
    end
    local background = select(2, grey(rect.x + 2, rect.y + 2))
    local comment, textX
    for y = rect.y + 4, rect.y + 200, 2 do
      for x = rect.x + 4, rect.x + 120, 2 do
        if not grey(x, y) then
          comment, textX = y, x
          break
        end
      end
      if comment then
        break
      end
    end
    assert(comment, "the comment is drawn")
    -- its leftmost coloured pixel, on any of its first row's rows of pixels
    for y = comment, comment + 12 do
      for x = rect.x + 4, textX - 1 do
        if not grey(x, y) then
          textX = x
          break
        end
      end
    end
    assert(textX - rect.x >= 20, "the text starts after the numbers' column, at " .. textX - rect.x)

    -- the column, up to a character before the text, holds only grey: each row's ink, a number's or the mark's, is a band of
    -- rows of pixels, and its picture is where they are bright
    local left, right = rect.x + 6, textX - 8
    local bands, band = {}, nil
    for y = rect.y + 4, math.min(rect.y + rect.height - 4, comment + 240) do
      local pixels = {}
      for x = left, right do
        local isGrey, level = grey(x, y)
        assert(isGrey, ("the numbers' column holds only grey, not at %d, %d"):format(x - rect.x, y - rect.y))
        pixels[#pixels + 1] = level >= background + 48 and "#" or "."
      end
      local picture = table.concat(pixels)
      if picture:find("#", 1, true) then
        band = band or { top = y, rows = {} }
        band.rows[#band.rows + 1] = picture
      elseif band then
        band.bottom, band.picture = y, table.concat(band.rows, "\n")
        bands[#bands + 1] = band
        band = nil
      end
    end

    -- the comment's first row shows 1, its next rows the mark, each the same, then the next lines show 2, 3 and on, each another picture
    local first
    for i, each in ipairs(bands) do
      if each.top <= comment and comment < each.bottom then
        first = i
      end
    end
    assert(first, "the comment's row has a number")
    local mark = bands[first + 1]
    assert(mark and mark.picture ~= bands[first].picture, "the comment's next row shows the mark, not a number")
    local after = first + 2
    while bands[after] and bands[after].picture == mark.picture do
      after += 1
    end
    local seen = { [bands[first].picture] = true, [mark.picture] = true }
    for i = after, after + 4 do
      assert(bands[i], "the lines after the comment have numbers")
      assert(not seen[bands[i].picture], "each line after the comment shows its own number")
      seen[bands[i].picture] = true
    end

    -- the title bar shows the tool's name, the core's menus that have functions here, then the gallery's buttons
    local function bar()
      local parts = {}
      for _, part in ipairs(test.titleBar()) do
        parts[part.label] = part
      end
      return parts
    end
    local parts = bar()
    test.match(parts, {
      Viewer = { kind = "name" },
      File = { kind = "menu" },
      ["\u{25B6}"] = { kind = "button", enabled = true },
      Slideshow = { kind = "button", on = false },
    }, "the title bar")

    local function click(label)
      local rect = bar()[label].rect
      test.click(rect.x + rect.width / 2, rect.y + rect.height / 2)
    end

    -- a click on a button runs its function: from the text to the image, and back
    click("\u{25B6}")
    test.match(viewer(), { title = "halves.png" }, "after Next")
    click("\u{25C0}")
    test.match(viewer(), { title = "init.lua" }, "after Previous")

    -- the slideshow's button is on while its setting is true, and the files go on by themselves
    click("Slideshow")
    test.match(bar().Slideshow, { on = true }, "the slideshow plays")
    test.wait(1.2)
    test.match(viewer(), { title = "halves.png" }, "the slideshow showed the next file")
    click("Slideshow")
    test.match(bar().Slideshow, { on = false }, "the slideshow stopped")
  end,
}
