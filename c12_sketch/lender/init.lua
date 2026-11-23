-- A plugin that frees a handle while Lua still holds it, so the test checks that the handle becomes invalid and the object lives on.
-- sketch_c.freeBrush frees a brush at once, as plugins whose objects hold much memory offer: Lua's handle to it stops working, and using
-- it raises an error, while a canvas that uses the brush keeps its own reference to it.

local ecs = require("ecs")
local sketch = require("sketch_c")

local freed -- what using the freed brush's handle raised

local function lend()
  local brush = sketch.brush(12, "blue")

  sketch.eachCanvas(function(panel)
    sketch.useBrush(brush, panel)
  end)

  sketch.freeBrush(brush)

  -- the handle is still a value in Lua, but it no longer stands for a brush
  local _, message = pcall(sketch.useBrush, brush, nil)
  freed = message
end

-- the plugin's state is saved in the session, so the test reads what the freed handle raised; it keeps nothing from the last session
ecs.plugin.register({
  saveState = function()
    return { freed = freed }
  end,
  restoreState = function() end,
})

ecs.service.register({
  lend = { sig = "void()", doc = "Give the C canvas a blue brush, and free the brush", fn = lend },
})
