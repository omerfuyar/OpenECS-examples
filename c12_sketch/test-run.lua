-- highlight sets each canvas's brush to yellow and 12 pixels for this run only, in the settings' run layer, above the preset's
-- values; again, the preset's come back. Two values for each canvas, four in all, check that the layer's values stay right as it
-- grows and shrinks. Strokes keep their colours, so each check draws a stroke of its own.

local COLORS = { "#BF616A", "#A3BE8C" } -- the preset's brushes: red for the C canvas, green for the Lua canvas
local YELLOW = "#EBCB8B"

return {
  preset = "preset.lua",
  run = function(test)
    for workspace = 1, 2 do
      test.call("ecs.workspace.switch" .. workspace)
      local id = test.session().workspaces[workspace].windows[1][1].panels[1].id
      local rect = test.rect(id)
      local plugin = workspace == 1 and "sketch_c" or "sketch_lua"
      local function stroke(y)
        test.drag(rect.x + 40, rect.y + y, rect.x + 240, rect.y + y)
        return test.pixel(rect.x + 140, rect.y + y)
      end

      test.call(plugin .. ".highlight")
      test.match(stroke(50), YELLOW, plugin .. ": the run's colour wins over the preset's")
      test.match(test.setting(plugin .. ".brushColor"), "yellow", plugin .. ": the value in effect")
      test.match(test.setting(plugin .. ".brushSize"), 12, plugin .. ": and the second value of the run")
      test.call(plugin .. ".highlight")
      test.match(stroke(120), COLORS[workspace], plugin .. ": the preset's colour comes back")
      test.match(test.setting(plugin .. ".brushSize") ~= 12, true, plugin .. ": and its size")
    end
  end,
}
