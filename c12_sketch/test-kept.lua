-- each canvas paints only the new part of a stroke on each draw, as its surface keeps the last picture, and tells the core what changed;
-- the whole stroke shows, a clear paints the canvas again, and a pop-out window, whose new texture takes the whole picture, shows it too

local COLORS = { "#BF616A", "#A3BE8C" } -- the preset's brushes: red for the C canvas, green for the Lua canvas
local BACKGROUND = "#2E3440"

-- the two strokes that strokes() draws, and a place away from them
local function check(test, rect, color, message)
  for _, x in ipairs({ 40, 140, 240 }) do
    test.match(test.pixel(rect.x + x, rect.y + 50), color, ("%s: the first stroke at %d"):format(message, x))
  end

  for _, y in ipairs({ 30, 120, 200 }) do
    test.match(test.pixel(rect.x + 60, rect.y + y), color, ("%s: the second stroke at %d"):format(message, y))
  end

  test.match(test.pixel(rect.x + 200, rect.y + 150), BACKGROUND, message .. ": away from the strokes")
end

-- each step of a drag draws the canvas again, with a few more points
local function strokes(test, rect)
  test.drag(rect.x + 40, rect.y + 50, rect.x + 240, rect.y + 50)
  test.drag(rect.x + 60, rect.y + 30, rect.x + 60, rect.y + 200)
end

return {
  preset = "preset.lua",
  run = function(test)
    local id

    for workspace = 1, 2 do
      test.call("ecs.workspace.switch" .. workspace)
      id = test.session().workspaces[workspace].windows[1][1].panels[1].id
      local rect = test.rect(id)
      local message = workspace == 1 and "the C canvas" or "the Lua canvas"

      strokes(test, rect)
      check(test, rect, COLORS[workspace], message)

      -- Delete asks, as the strokes are unsaved, and Return clears; the next strokes show on the cleared canvas
      test.key("Delete")
      test.key("Return")
      test.match(test.pixel(rect.x + 140, rect.y + 50), BACKGROUND, message .. ": cleared")
      strokes(test, rect)
      check(test, rect, COLORS[workspace], message .. ", after the clear")
    end

    test.call("ecs.layout.popOut")
    test.window(2)
    check(test, test.rect(id), COLORS[2], "the Lua canvas in its own window")
  end,
}
