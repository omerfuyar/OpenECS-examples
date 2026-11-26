-- fs's recursive watch from Lua: the watcher plugin watches a folder and the folders inside it, and is told of each change in any of them
local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks_watch.lua")

return {
  preset = "preset_watch.lua",
  run = function(test)
    checks(test, "watcher")
    test.match(test.errors(), {}, "the errors")
  end,
}
