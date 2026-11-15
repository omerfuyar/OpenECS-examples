-- the files panel shows the tool's folder: a second click opens a file through the tool's handler, New makes the tool's
-- own kind of file, and Rename and Delete change the folder
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
    test.wait(0.3)

    -- the panel's rows: its name field, the kinds and New, then Rename and Delete, then the folder's files by name
    local panel = test.rect(idOf("files.tree"))
    local function row(i)
      return panel.x + 60, panel.y + 84 + 21 * (i - 1)
    end

    -- one click chooses a file, and a second one soon after opens it with the tool's handler
    local x, y = row(1)
    test.click(x, y)
    test.click(x, y)
    test.match(notes(), { opened = "apples.txt" }, "the second click opens the file")

    -- New makes the kind that the dropdown names: Folder, the tool's Note, or File
    test.click(panel.x + 100, panel.y + 21)
    test.text("milk")
    test.click(panel.x + panel.width - 98, panel.y + 21)
    test.key("Down")
    test.key("Return")
    test.click(panel.x + panel.width - 33, panel.y + 21)
    assert(waitFor(function()
      return exists(folder .. "milk.txt")
    end), "New makes a note with the tool's make")

    -- Rename gives the chosen file the name in the field
    x, y = row(2)
    test.click(x, y)
    test.click(panel.x + 100, panel.y + 21)
    test.key("Ctrl+A")
    test.text("bread.txt")
    test.click(panel.x + 43, panel.y + 54)
    assert(waitFor(function()
      return exists(folder .. "bread.txt") and not exists(folder .. "milk.txt")
    end), "Rename renames the chosen file")

    -- Delete asks first
    test.click(x, y)
    test.click(panel.x + 111, panel.y + 54)
    test.match(test.dialog(), { title = "Delete bread.txt" }, "Delete asks")
    test.key("Return")
    assert(waitFor(function()
      return not exists(folder .. "bread.txt")
    end), "the answer deletes the file")
  end,
}
