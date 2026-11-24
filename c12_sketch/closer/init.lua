-- A panel that breaks a rule on purpose, so the test checks that the core stops it.
-- The core walks the layout while panels draw, so a draw that opens, moves or closes a panel misuses the function: the panel faults.
-- A panel changes the layout in an event, a timer or a function instead.

local ecs = require("ecs")

local Closer = {}
Closer.__index = Closer

function Closer.create(panel)
  return setmetatable({ panel = panel }, Closer)
end

function Closer:draw(surface)
  surface:fill(0, 0, surface.width, surface.height, "panel")
  ecs.layout.close(self.panel)
end

ecs.panel.registerType({ name = "panel", title = "Closer", create = Closer.create, draw = Closer.draw })
