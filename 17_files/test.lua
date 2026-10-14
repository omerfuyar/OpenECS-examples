-- the browser starts in its plugin's folder, which holds the plugin's files, and follows the folder's changes
return {
  preset = "preset.lua",
  run = function(test)
    local function names()
      return test.session().workspaces[1].windows[1].panels[1].state.names
    end

    local folder = test.session().workspaces[1].windows[1].panels[1].state.folder
    assert(folder:match("files/$"), "the folder: " .. folder)
    test.match(names(), { "init.lua", "manifest.lua" }, "the folder's entries")

    -- a file added to the folder shows in the list, and leaves it when it is removed
    local path = folder .. "watched.ignore"
    local file = assert(io.open(path, "w"))
    file:write("watched")
    file:close()
    test.wait(0.5)
    test.match(names(), { "init.lua", "manifest.lua", "watched.ignore" }, "the entries with the added file")

    os.remove(path)
    test.wait(0.5)
    test.match(names(), { "init.lua", "manifest.lua" }, "the entries after the file is removed")
  end,
}
