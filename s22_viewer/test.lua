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

    -- the file's first line, a comment, is too long for the panel: the rows it wraps into start with a dim mark, grey, where the comment's
    -- own colour is not; down the first column, past the path above and the comment's first row, a bright grey pixel is the mark
    local function channels(color)
      return tonumber(color:sub(2, 3), 16), tonumber(color:sub(4, 5), 16), tonumber(color:sub(6, 7), 16)
    end
    local x = rect.x + 10
    local panelColor = channels(test.pixel(x, rect.y + 2))
    local comment, mark
    for y = rect.y + 4, rect.y + 200 do
      local r, g, b = channels(test.pixel(x, y))
      local grey = r == g and g == b
      comment = comment or (not grey and y)
      if comment and grey and r >= panelColor + 48 then
        mark = y
        break
      end
    end
    assert(comment and mark, "the rows of a wrapped line start with a dim mark")

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
