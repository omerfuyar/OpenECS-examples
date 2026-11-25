-- a tooltip is not cut by its narrow panel: ui shows it in a popup, which goes past the panel's right edge, over the panel beside it, in
-- Lua and in C alike

return {
  preset = "preset_narrow.lua",
  run = function(test)
    for number = 1, 2 do
      local panel = test.rect(number)
      local button = test.panel(number).state.rects.button
      test.move(panel.x + button.x + button.width / 2, panel.y + button.y + button.height / 2)
      test.wait(0.8)
      local tip = test.popup(1)
      test.match(tip.x + tip.width > panel.x + panel.width, true, "the tooltip past the edge of panel " .. number)
      test.move(panel.x + 2, panel.y + panel.height - 2)
    end
  end,
}
