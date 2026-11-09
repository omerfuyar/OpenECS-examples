-- Panels that draw a path through the points clicked on them, and show its length. The points are geometry's vectors, a struct type in C.

local ecs = require("ecs")
local draw = require("draw")

local STATE_VERSION = 1

-- a struct is a table of its fields, with its type's methods: a function gives one, and ecs.struct.new makes one from a table of the fields
local function point(x, y)
  return ecs.struct.new("geometry.vec2", { x = x, y = y })
end

-- the path's length: each step is a vector from one point to the next, and a - b and :length() run geometry's functions in C
local function length(points)
  local total = 0

  for i = 2, #points do
    total = total + (points[i] - points[i - 1]):length()
  end

  return total
end

local function update(state)
  state.panel.title = ("Path (%d)"):format(math.floor(length(state.points) + 0.5))
  state.panel:redraw()
end

ecs.panel.registerType({
  name = "panel",
  title = "Path",
  stateVersion = STATE_VERSION,

  create = function(panel, saved, version)
    local state = { panel = panel, points = {}, scale = 1 }

    -- a saved struct comes back as a plain table of its fields; functions take any such table, and ecs.struct.new gives back its methods
    if version == STATE_VERSION and saved then
      for _, saved_point in ipairs(saved.points) do
        table.insert(state.points, ecs.struct.new("geometry.vec2", saved_point))
      end
    end

    update(state)
    return state
  end,

  draw = function(state, surface)
    state.scale = surface.scale
    surface:fill(0, 0, surface.width, surface.height, "background")

    -- fields are read as in any table
    for i, p in ipairs(state.points) do
      if i > 1 then
        draw.line(surface, state.points[i - 1].x, state.points[i - 1].y, p.x, p.y, 2, "text")
      end

      draw.circle(surface, p.x, p.y, 4, 0, "accent")
    end
  end,

  event = function(state, event)
    if event.type == "pointerDown" and event.button == 1 then
      -- points are kept in layout units, so the path stays put at any scale; a method can take more arguments after the struct
      local clicked = point(event.x, event.y):scale(1 / state.scale)

      -- == runs geometry's equal: a click on the last point adds nothing
      if clicked ~= state.points[#state.points] then
        table.insert(state.points, clicked)
        update(state)
      end
    elseif event.type == "pointerDown" and event.button == 3 then
      state.points = {}
      update(state)
    end
  end,

  -- a struct is plain data, so it is saved as any table of numbers is
  saveState = function(state)
    return { points = state.points }
  end,
})
