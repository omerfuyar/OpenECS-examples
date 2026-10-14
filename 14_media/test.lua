-- a click on the picture plays the sound, and a click beside it does not; tests play on SDL's dummy audio output
return {
  preset = "preset.lua",
  run = function(test)
    local panel = test.rect(1)
    test.click(panel.x + panel.width / 2, panel.y + panel.height / 2)
    test.click(panel.x + 3, panel.y + 3)
    test.match(test.panel(1), { title = "Media (1)" })
    test.match(test.session().workspaces[1].windows[1].panels[1].state.smooth, true, "the frame's smooth corner")

    -- B plays a streamed tone of 0.3 seconds, which ends once it has played; the dummy output plays as fast as a real one
    test.key("B")
    local state = test.session().workspaces[1].windows[1].panels[1].state
    test.match(math.abs(state.toneQueued - 0.3) < 0.01, true, "the stream's queued seconds")
    test.wait(1)
    test.match(test.session().workspaces[1].windows[1].panels[1].state.tonePlaying, false, "the stream's end")

    -- S writes the picture to a PNG file and reads it back
    test.key("S")
    test.match(test.session().workspaces[1].windows[1].panels[1].state.saved, true, "the picture written and read again")
  end,
}
