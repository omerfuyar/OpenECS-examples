-- the video opens paused at its start with its first frame; Space plays it, Right goes forward, and it stops at its end
return {
  preset = "preset.lua",
  run = function(test)
    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    local start = state()
    test.match(start, { playing = false, time = 0, width = 160, height = 120 }, "the video at start")
    assert(math.abs(start.duration - 2) < 0.1, "a video of two seconds, not " .. start.duration)

    -- the first frame shows before it plays: the middle of the panel is not its background
    local panel = test.rect(1)
    assert(test.pixel(panel.x + panel.width / 2, panel.y + (panel.height - 40) / 2) ~= test.setting("ecs.colorBackground"):sub(1, 7), "the first frame")

    test.key("Space")
    test.wait(0.5)
    local played = state()
    assert(played.playing and played.time > 0.2, ("playing for half a second: %s at %.2f"):format(tostring(played.playing), played.time))

    -- Right goes half a second forward, and the video plays to its end, where it stops
    test.key("Right")
    assert(state().time > played.time + 0.4, "half a second forward")
    test.wait(2)
    test.match(state(), { playing = false }, "at its end")
  end,
}
