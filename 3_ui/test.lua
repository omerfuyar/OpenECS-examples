-- clicks on the button count, and clicks beside it do not
return {
  preset = "preset.lua",
  run = function(test)
    local panel = test.rect(1)

    -- the column centres the button below the text; the button is about 30 units tall, starting about 60 units down
    local x, y = panel.x + panel.width / 2, panel.y + 24 + 22 + 12 + 14
    test.click(x, y)
    test.click(x, y)
    test.click(panel.x + 5, panel.y + 5)
    test.match(test.panel(1), { title = "Button (2)" })
  end,
}
