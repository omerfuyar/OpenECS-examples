-- the controls at ecs.scale 1.25 pass the same checks: events give positions in the surface's pixels, which ui divides by the scale, and a popup
-- opens at its size in layout units times the scale

local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset_large.lua",
  run = function(test)
    test.match(test.setting("ecs.scale"), 1.25, "the scale")
    checks(test, 1, "Controls")
  end,
}
