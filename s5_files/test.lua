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
    test.wait(0.3)

    -- the panel's rows: the folder's files by name
    local panel = test.rect(idOf("files.tree"))
    local function row(i)
      return panel.x + 60, panel.y + 18 + 21 * (i - 1)
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
    test.key("Down")
    test.key("Return")
    -- the field shows, and takes the keys, at the panel's next draw
    test.wait()
    test.text("milk")
    test.key("Return")
    assert(waitFor(function()
      return exists(folder .. "milk.txt")
    end), "New makes a note with the tool's make")

    -- a right click on a file chooses it, and its menu's Rename, the entry before the last, asks for the new name
    x, y = row(2)
    test.click(x, y, 3)
    test.key("Up")
    test.key("Up")
    test.key("Return")
    test.wait()
    test.key("Ctrl+A")
    test.text("bread.txt")
    test.key("Return")
    assert(waitFor(function()
      return exists(folder .. "bread.txt") and not exists(folder .. "milk.txt")
    end), "Rename renames the chosen file")

    -- Delete, the last entry, asks first
    test.click(x, y, 3)
    test.key("Up")
    test.key("Return")
    test.match(test.dialog(), { title = "Delete bread.txt" }, "Delete asks")
    test.key("Return")
    assert(waitFor(function()
      return not exists(folder .. "bread.txt")
    end), "the answer deletes the file")
  end,
}
