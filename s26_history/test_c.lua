-- the tally in C passes the checks of the tally in Lua: its changes are records of the history plugin, which C functions undo and redo with the
-- data that each record keeps

local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset_c.lua",
  run = function(test)
    checks(test, 1, "tally_c")
  end,
}
