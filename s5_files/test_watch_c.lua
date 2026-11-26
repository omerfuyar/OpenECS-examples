-- fs's recursive watch from C: watcher_c, the watcher plugin in C, passes the checks of the plugin in Lua
local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks_watch.lua")

return {
  preset = "preset_watch.lua",
  run = function(test)
    checks(test, "watcher_c")
    test.match(test.errors(), {}, "the errors")
  end,
}
