-- the controls in Lua, on workspace 1: each control changes the panel's state, as the checks that the C plugin passes too say

local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset.lua",
  run = function(test)
    checks(test, 1, "Controls")
  end,
}
