-- a colour dragged from the palette colours the sample, which marks the pointer while the colour is over it; files dropped on it show their names
return {
  preset = "preset.lua",
  run = function(test)
    local palette, sample = test.rect(1), test.rect(2)
    local x, y = sample.x + 50, sample.y + 50

    -- the third swatch, held over the sample: the sample gets the pointer's moves and marks the pointer
    test.press(palette.x + 2 * 48 + 10, palette.y + 10)
    test.move(sample.x + 20, y)
    test.move(x, y)
    test.match({ marked = test.pixel(x, y) ~= test.pixel(x + 30, y) }, { marked = true }, "the sample marks the pointer during the drag")
    test.release(x, y)

    test.dropFiles(x, y, { "/home/someone/notes.txt", "/home/someone/photo.png" })

    local state = test.session().workspaces[1].windows[1][2].panels[1].state
    test.match(state, { color = "#EBCB8B", files = { "notes.txt", "photo.png" } })
  end,
}
