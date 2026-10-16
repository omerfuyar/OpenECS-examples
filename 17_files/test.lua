-- the browser starts in its plugin's folder, which holds the plugin's files, and follows the folder's changes
return {
  preset = "preset.lua",
  run = function(test)
    local function names()
      return test.session().workspaces[1].windows[1].panels[1].state.names
    end

    -- waits up to 5 seconds for the list to hold the expected count of entries
    local function waitCount(count)
      for _ = 1, 100 do
        if #names() == count then
          return
        end
        test.wait(0.05)
      end
    end

    local folder = test.session().workspaces[1].windows[1].panels[1].state.folder
    assert(folder:match("files/$"), "the folder: " .. folder)

    -- a file left by a run that stopped early goes first
    local path = folder .. "watched.ignore"
    os.remove(path)
    waitCount(2)
    test.match(names(), { "init.lua", "manifest.lua" }, "the folder's entries")

    -- a file added to the folder shows in the list, and leaves it when it is removed
    local file = assert(io.open(path, "w"))
    file:write("watched")
    file:close()
    waitCount(3)
    test.match(names(), { "init.lua", "manifest.lua", "watched.ignore" }, "the entries with the added file")

    os.remove(path)
    waitCount(2)
    test.match(names(), { "init.lua", "manifest.lua" }, "the entries after the file is removed")
  end,
}
