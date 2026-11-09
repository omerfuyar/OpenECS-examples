-- the Lua canvas paints only the new part of a stroke on each draw, as its surface keeps the last picture; the whole stroke shows,
-- and a pop-out window, whose new texture takes the whole picture, shows it too

local GREEN, BACKGROUND = "#A3BE8C", "#2E3440"

return {
  preset = "preset.lua",
  run = function(test)
    test.call("ecs.workspace.switch2")
    local id = test.session().workspaces[2].windows[1][1].panels[1].id
    local canvas = test.rect(id)

    -- each step of a drag draws the canvas again, with a few more points
    test.drag(canvas.x + 40, canvas.y + 50, canvas.x + 240, canvas.y + 50)
    test.drag(canvas.x + 60, canvas.y + 30, canvas.x + 60, canvas.y + 200)

    local function check(rect, message)
      for _, x in ipairs({ 40, 140, 240 }) do
        test.match(test.pixel(rect.x + x, rect.y + 50), GREEN, ("%s: the first stroke at %d"):format(message, x))
      end

      for _, y in ipairs({ 30, 120, 200 }) do
        test.match(test.pixel(rect.x + 60, rect.y + y), GREEN, ("%s: the second stroke at %d"):format(message, y))
      end

      test.match(test.pixel(rect.x + 200, rect.y + 150), BACKGROUND, message .. ": away from the strokes")
    end

    check(canvas, "in the main window")

    test.call("ecs.layout.popOut")
    test.window(2)
    check(test.rect(id), "in its own window")
  end,
}
