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

-- each panel's state is an object of Path, whose functions are methods
local Path = {}
Path.__index = Path

function Path:update()
  self.panel.title = ("Path (%d)"):format(math.floor(length(self.points) + 0.5))
  self.panel:redraw()
end

function Path.create(panel, saved, version)
  local state = setmetatable({ panel = panel, points = {}, scale = 1 }, Path)

  -- a saved struct comes back as a plain table of its fields; functions take any such table, and ecs.struct.new gives back its methods
  if version == STATE_VERSION and saved then
    for _, saved_point in ipairs(saved.points) do
      table.insert(state.points, ecs.struct.new("geometry.vec2", saved_point))
    end
  end

  state:update()
  return state
end

function Path:draw(surface)
  self.scale = surface.scale
  surface:fill(0, 0, surface.width, surface.height, "background")

  -- fields are read as in any table
  for i, p in ipairs(self.points) do
    if i > 1 then
      draw.line(surface, self.points[i - 1].x, self.points[i - 1].y, p.x, p.y, 2, "text")
    end

    draw.circle(surface, p.x, p.y, 4, 0, "accent")
  end
end

function Path:event(event)
  if event.type == "pointerDown" and event.button == 1 then
    -- points are kept in layout units, so the path stays put at any scale; a method can take more arguments after the struct
    local clicked = point(event.x, event.y):scale(1 / self.scale)

    -- == runs geometry's equal: a click on the last point adds nothing
    if clicked ~= self.points[#self.points] then
      table.insert(self.points, clicked)
      self:update()
    end
  elseif event.type == "pointerDown" and event.button == 3 then
    self.points = {}
    self:update()
  end
end

-- a struct is plain data, so it is saved as any table of numbers is
function Path:saveState()
  return { points = self.points }
end

ecs.panel.registerType({
  name = "panel",
  title = "Path",
  stateVersion = STATE_VERSION,

  create = Path.create,

  draw = Path.draw,

  event = Path.event,

  saveState = Path.saveState,
})
