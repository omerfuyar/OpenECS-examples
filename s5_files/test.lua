-- the files panel shows the tool's folder: a click chooses a file and a double click opens it, through the tool's handlers;
-- it follows the folder's changes, and its right click's menu makes the tool's own kind of file, renames and deletes
return {
  preset = "preset.lua",
  run = function(test)
    -- a panel's id by its type
    local function idOf(type)
      for _, panel in ipairs(test.panels()) do
        if panel.type == type then
          return panel.id
        end
      end
    end
    local function notes()
      return test.panel(idOf("notes.opened")).state
    end
    local function exists(path)
      local file = io.open(path, "rb")
      if file then
        file:close()
      end
      return file ~= nil
    end
    -- waits up to 5 seconds, as the panel follows the folder through fs's watch
    local function waitFor(condition)
      for _ = 1, 100 do
        if condition() then
          return true
        end
        test.wait(0.05)
      end
      return false
    end

    local folder = notes().folder
    -- files that a run that stopped early left go first
    os.remove(folder .. "milk.txt")
    os.remove(folder .. "bread.txt")
    os.remove(folder .. "banana.txt")
    os.remove(folder .. "dropped.txt")
    os.remove(folder .. "dropped 2.txt")
    os.remove(folder .. "box/inside.txt")
    os.remove(folder .. "box")
    os.remove(folder .. "zebra crossing on a very long road.txt")
    test.wait(0.3)

    -- the panel's rows, below the selector of the tree and the grid: the folder's files by name
    local panel = test.rect(idOf("files.tree"))
    local function row(i)
      return panel.x + 60, panel.y + 51 + 21 * (i - 1)
    end

    -- one click chooses a file, and a second one soon after opens it, each with the tool's handler
    local x, y = row(1)
    test.click(x, y)
    test.match(notes(), { chosen = "apples.txt", opened = "" }, "a click chooses the file")
    test.click(x, y)
    test.match(notes(), { chosen = "apples.txt", opened = "apples.txt" }, "a double click opens the file")

    -- a file that another program writes into the folder shows in the panel, in its place by name
    local file = assert(io.open(folder .. "banana.txt", "wb"))
    file:write("Yellow.\n")
    file:close()
    x, y = row(2)
    assert(waitFor(function()
      test.click(x, y)
      return notes().chosen == "banana.txt"
    end), "the panel follows the folder")
    os.remove(folder .. "banana.txt")
    test.wait(1)

    -- a right click beside the files opens the menu of New: a folder, the tool's note, or a file; the note's entry asks for a name
    -- in a field above the files, which has the keys, and Return makes it with the tool's make
    test.click(panel.x + 60, panel.y + panel.height - 20, 3)
    test.choose("New note")
    -- the field shows, and takes the keys, at the panel's next draw
    test.wait()
    test.text("milk")
    test.key("Return")
    assert(waitFor(function()
      return exists(folder .. "milk.txt")
    end), "New makes a note with the tool's make")

    -- a right click on a file chooses it, and its menu's Rename asks for the new name
    x, y = row(2)
    test.click(x, y, 3)
    test.choose("Rename")
    test.wait()
    test.key("Ctrl+A")
    test.text("bread.txt")
    test.key("Return")
    assert(waitFor(function()
      return exists(folder .. "bread.txt") and not exists(folder .. "milk.txt")
    end), "Rename renames the chosen file")

    -- the grid shows the folder as tiles, which a click chooses and a double click opens, as the tree's rows do
    test.click(panel.x + 80, panel.y + 20)
    test.click(panel.x + 138, panel.y + 110)
    test.match(notes(), { chosen = "bread.txt" }, "a click on a tile chooses the file")
    test.click(panel.x + 138, panel.y + 110)
    test.match(notes(), { opened = "bread.txt" }, "a double click on a tile opens it")
    -- a long name wraps onto a second line, and is cut there with an ellipsis at its tile's width, so nothing is drawn in the gap before the
    -- next tile
    local long = "zebra crossing on a very long road.txt"
    file = assert(io.open(folder .. long, "wb"))
    file:write("Long.\n")
    file:close()
    test.wait(1)
    test.move(panel.x + 10, panel.y + panel.height - 10)
    test.wait()
    local gap = test.pixel(panel.x + 270, panel.y + 70)
    for y = panel.y + 70, panel.y + 160 do
      for x = panel.x + 269, panel.x + 271 do
        test.match(test.pixel(x, y), gap, ("nothing is drawn between the tiles at %d, %d"):format(x - panel.x, y - panel.y))
      end
    end
    -- the long name's tile is the fourth, and its name's second line is drawn below the first
    local drawn = false
    for y = panel.y + 144, panel.y + 154 do
      for x = panel.x + 276, panel.x + 352 do
        drawn = drawn or test.pixel(x, y) ~= gap
      end
    end
    test.match(drawn, true, "the long name's second line")
    os.remove(folder .. long)
    test.wait(0.5)
    test.click(panel.x + 30, panel.y + 20)

    -- the search field beside the selector shows only the files whose name holds its text, whatever its case
    test.click(panel.x + panel.width - 80, panel.y + 20)
    test.text("PLUM")
    test.wait()
    test.click(row(1))
    test.match(notes(), { chosen = "plumber.txt" }, "the search shows only plumber.txt")
    test.click(panel.x + panel.width - 80, panel.y + 20)
    test.key("Ctrl+A")
    test.key("Backspace")
    test.wait()

    -- Delete asks first
    test.click(x, y, 3)
    test.choose("Delete")
    test.match(test.dialog(), { title = "Delete bread.txt" }, "Delete asks")
    test.key("Return")
    assert(waitFor(function()
      return not exists(folder .. "bread.txt")
    end), "the answer deletes the file")

    -- a file that another application drops on the panel is copied into the folder under the pointer: beside the files, the
    -- shown folder; a second drop of it gets a free name
    os.remove(folder .. "dropped.txt")
    os.remove(folder .. "dropped 2.txt")
    local outside = folder .. "../dropped.txt"
    file = assert(io.open(outside, "wb"))
    file:write("From elsewhere.\n")
    file:close()
    test.dropFiles(panel.x + 60, panel.y + panel.height - 20, { outside })
    assert(waitFor(function()
      return exists(folder .. "dropped.txt")
    end), "a dropped file is copied into the folder")
    local rx, ry = row(1)
    test.dropFiles(rx, ry, { outside })
    assert(waitFor(function()
      return exists(folder .. "dropped 2.txt")
    end), "dropped on a file, into its folder, under a free name")
    os.remove(folder .. "dropped.txt")
    os.remove(folder .. "dropped 2.txt")
    os.remove(outside)
    -- the panel lists the folder again when fs's watch tells it of the change
    test.wait(0.5)

    -- Show in Files chooses the opened note in the files panel, without the tool's choose; a locked panel stays where it is
    local files = idOf("files.tree")
    local opened = test.rect(idOf("notes.opened"))
    x, y = row(1)
    test.click(x, y)
    test.click(x, y)
    x, y = row(2)
    test.click(x, y)
    test.match(test.panel(files).state, { selected = "plumber.txt" }, "plumber.txt is chosen")
    test.click(opened.x + 50, opened.y + 20)
    test.wait()
    test.match(test.panel(files).state, { selected = "apples.txt" }, "Show in Files chooses the opened note")
    test.match(notes(), { chosen = "plumber.txt" }, "without the tool's choose")
    test.click(x, y)
    test.call("files.lock")
    test.click(opened.x + 50, opened.y + 20)
    test.wait()
    test.match(test.panel(files).state, { selected = "plumber.txt", locked = true }, "a locked panel stays")
    test.click(x, y)
    test.call("files.lock")
    test.match(test.panel(files).state, { locked = false }, "and unlocks")

    -- a folder made after the panel opened is watched too: a file that another program writes into it shows when the folder opens
    local function selected()
      return test.panel(files).state.selected
    end
    test.click(panel.x + 60, panel.y + panel.height - 20, 3)
    test.choose("New folder")
    test.wait()
    test.text("box")
    test.key("Return")
    x, y = row(1)
    assert(waitFor(function()
      test.click(x, y)
      return selected() == "box"
    end), "New folder makes a folder, first in the tree")
    test.key("Right")
    file = assert(io.open(folder .. "box/inside.txt", "wb"))
    file:write("Inside.\n")
    file:close()
    x, y = row(2)
    assert(waitFor(function()
      test.click(x, y)
      return selected() == "box/inside.txt"
    end), "the new folder is watched")
    os.remove(folder .. "box/inside.txt")
    x, y = row(1)
    test.click(x, y, 3)
    test.choose("Delete")
    test.match(test.dialog(), { title = "Delete box" }, "Delete asks about the folder")
    test.key("Return")
    assert(waitFor(function()
      test.click(x, y)
      return selected() == "apples.txt"
    end), "the folder is deleted")
  end,
}
