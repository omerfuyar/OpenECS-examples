-- the sample in C passes the checks of the sample in Lua: its events are the same, DragOver, DragLeave and Drop
local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset_c.lua",
  run = function(test)
    checks(test, "the sample in C")
  end,
}
