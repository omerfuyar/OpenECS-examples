-- the core measures where the time goes while the setting ecs.profile is on; the profiler's Measure switch sets it, and its tables
-- show each plugin's own time: busy's calls into draw count as draw's, not busy's
return {
  preset = "preset.lua",
  run = function(test)
    local busy, profiler
    for _, panel in ipairs(test.panels()) do
      if panel.type == "busy.panel" then
        busy = panel.id
      elseif panel.type == "profiler.view" then
        profiler = panel.id
      end
    end
    local view = test.rect(profiler)

    -- while ecs.profile is off, the core measures nothing, and ecs.profile.get gives nil
    test.match(test.panel(busy).state, { measured = false }, "nothing is measured at first")

    -- the switch sets ecs.profile in the user's settings; the profile sums plugins' times over a whole second
    test.click(view.x + 40, view.y + 75)
    test.match(test.setting("ecs.profile"), true, "Measure turns ecs.profile on")
    test.wait(1.7)
    test.match(test.panel(busy).state, { measured = true, busy = true, draw = true }, "busy and draw each have their own time")

    -- the tabs choose the table, and Pause keeps the numbers; the panel saves both
    test.click(view.x + 120, view.y + 142)
    test.click(view.x + 139, view.y + 75)
    test.match(test.panel(profiler).state, { tab = 2, paused = true }, "the Panels tab and Pause are kept")

    test.click(view.x + 40, view.y + 75)
    test.match(test.setting("ecs.profile"), false, "Measure turns ecs.profile off")
    test.match(test.panel(busy).state, { measured = false }, "nothing is measured once it is off")
  end,
}
