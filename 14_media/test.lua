-- a click on the picture plays the sound, and a click beside it does not; tests play on SDL's dummy audio output
return {
  preset = "preset.lua",
  run = function(test)
    local panel = test.rect(1)
    test.click(panel.x + panel.width / 2, panel.y + panel.height / 2)
    test.click(panel.x + 3, panel.y + 3)
    test.match(test.panel(1), { title = "Media (1)" })
  end,
}
