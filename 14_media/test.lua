-- a click on the picture plays the sound, and a click beside it does not; tests play on SDL's dummy audio output
return {
  preset = "preset.lua",
  run = function(test)
    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    local panel = test.rect(1)
    test.click(panel.x + panel.width / 2, panel.y + panel.height / 2)
    test.click(panel.x + 3, panel.y + 3)
    test.match(test.panel(1), { title = "Media (1)" })
    test.match(state().smooth, true, "the frame's smooth corner")

    -- B plays a streamed tone of 0.3 seconds, which ends once it has played; the dummy output plays as fast as a real one
    test.key("B")
    test.match(math.abs(state().toneQueued - 0.3) < 0.01, true, "the stream's queued seconds")
    test.wait(1)
    test.match(state().tonePlaying, false, "the stream's end")

    -- S writes the picture to a PNG file and reads it back
    test.key("S")
    test.match(state().saved, true, "the picture written and read again")

    -- the probe on the note's stem is white and the other blue; two quarter turns swap them, and fading darkens the white one
    local function red(probe)
      return tonumber(probe:sub(2, 3), 16)
    end

    local probes = state().probes
    test.match({ red(probes[1]) > 200, red(probes[2]) < 100 }, { true, true }, "the stem and beside it")
    -- the spinner has eight frames of a tenth of a second, and moves on by itself
    local first = state().frame
    test.match({ state().frames, state().frameSeconds }, { 8, 0.1 }, "the GIF's frames")
    test.wait(0.35)
    test.match(state().frame ~= first, true, "the next frame")

    test.key("R")
    test.key("R")
    probes = state().probes
    test.match({ red(probes[1]) < 100, red(probes[2]) > 200 }, { true, true }, "the picture turned by half a turn")
    test.key("F")
    probes = state().probes
    test.match(red(probes[2]) > 100 and red(probes[2]) < 200, true, "the faded picture")
  end,
}
