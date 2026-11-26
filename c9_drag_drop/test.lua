-- a colour dragged from the palette colours the sample, which marks the pointer while the colour is over it; a colour dragged within the palette
-- moves there, and the palette shows the gap where it will land; files dropped on the sample show their names
local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset.lua",
  run = function(test)
    checks(test, "the sample")

    -- the first swatch, held over the gap between the fourth and the fifth: the palette that started the drag gets dragOver too, and draws a
    -- line in the gap
    local palette = test.rect(1)
    local gapX, y = palette.x + 4 * 48, palette.y + 10

    local function line()
      return test.pixel(gapX, y) ~= test.pixel(gapX + 10, y)
    end

    test.press(palette.x + 10, y)
    test.move(palette.x + 100, y)
    test.move(gapX + 5, y)
    test.match(line(), true, "the palette marks the gap during its own drag")
    test.release(gapX + 5, y)
    test.match(line(), false, "the palette drops its mark after the drop")

    local session = test.session().workspaces[1].windows[1]
    test.match(session[1].panels[1].state.colors, { "#D08770", "#EBCB8B", "#A3BE8C", "#BF616A", "#5E81AC", "#B48EAD" }, "the swatch moved to the gap")

    local sample = test.rect(2)
    test.dropFiles(sample.x + 50, sample.y + 50, { "/home/someone/notes.txt", "/home/someone/photo.png" })
    test.match(test.session().workspaces[1].windows[1][2].panels[1].state.files, { "notes.txt", "photo.png" }, "the names of the dropped files")
  end,
}
