-- the core measures where the time goes while the setting ecs.profile is on; the profiler's Measure switch sets it, and its tables
-- show each plugin's own time: busy's calls into draw count as draw's, not busy's. LuaJIT's samples find busy's Lua function wave
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
    test.click(view.x + 40, view.y + 16)
    test.match(test.setting("ecs.profile"), true, "Measure turns ecs.profile on")
    test.wait(1.7)

    -- LuaJIT samples every millisecond, so a slow machine may need another second before a sample falls in wave
    for _ = 1, 8 do
      if test.panel(busy).state.wave then
        break
      end
      test.wait(0.5)
    end

    test.match(test.panel(busy).state, { measured = true, busy = true, draw = true, wave = true }, "busy and draw each have their own time, and wave is busy's")

    -- Pause keeps the numbers, and the tabs choose the table; the panel saves both. A click gives Pause the keys, and Tab goes on past Copy
    -- report to the tabs, where Right chooses the next one
    test.click(view.x + 139, view.y + 16)
    test.key("Tab")
    test.key("Tab")
    test.key("Right")
    test.match(test.panel(profiler).state, { tab = 2, paused = true }, "the Panels tab and Pause are kept")

    test.click(view.x + 40, view.y + 16)
    test.match(test.setting("ecs.profile"), false, "Measure turns ecs.profile off")
    test.match(test.panel(busy).state, { measured = false }, "nothing is measured once it is off")
  end,
}
