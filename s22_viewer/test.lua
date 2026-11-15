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
  end,
}
