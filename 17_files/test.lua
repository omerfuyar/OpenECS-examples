-- the browser starts in its plugin's folder, which holds the plugin's files
return {
  preset = "preset.lua",
  run = function(test)
    local state = test.session().workspaces[1].windows[1].panels[1].state
    assert(state.folder:match("files/$"), "the folder: " .. state.folder)
    test.match(state.names, { "init.lua", "manifest.lua" }, "the folder's entries")
  end,
}
