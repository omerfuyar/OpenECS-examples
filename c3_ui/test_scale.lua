-- the controls at ecs.scale 1.25 pass the same checks: events give positions in the surface's pixels, which ui divides by the scale, and a popup
-- opens at its size in layout units times the scale. The scale changes while the tool runs, as the user's settings file changes it

local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset.lua",
  run = function(test)
    test.setSetting("ecs.scale", 1.25)
    test.match(test.setting("ecs.scale"), 1.25, "the scale")
    checks(test, 1, "Controls")
  end,
}
