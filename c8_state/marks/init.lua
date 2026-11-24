-- Panels that keep the dots clicked on them. Sessions save each panel's dots, and the plugin's count of every dot placed.
-- A session is a tool as it was left: OpenECS saves it when the tool quits and builds the tool from it next time.

local ecs = require("ecs")

local draw = require("draw") -- the functions of a plugin the manifest depends on

-- raise it when the saved state changes shape; create then gets the old version, and can read or drop the old state
local STATE_VERSION = 1
local DOT = 8 -- in layout units

local placed = 0 -- every dot placed, in every session; the plugin's own state

-- each panel's state is an object of Marks, whose functions are methods
local Marks = {}
Marks.__index = Marks

-- saved is the state saveState gave last time, or nil for a new panel
function Marks.create(panel, saved, version)
  local marks = setmetatable({ panel = panel, dots = {}, scale = 1 }, Marks)

  if version == STATE_VERSION and saved then
    marks.dots = saved.dots
  end

  return marks
end

function Marks:draw(surface)
  self.scale = surface.scale
  surface:fill(0, 0, surface.width, surface.height, "panel")

  for i = 1, #self.dots - 1, 2 do
    draw.fill(surface, self.dots[i] - DOT / 2, self.dots[i + 1] - DOT / 2, DOT, DOT, "accent")
  end
end

function Marks:event(event)
  if event.type == "pointerDown" and event.button == 1 then
    table.insert(self.dots, event.x / self.scale) -- dots are kept in layout units, so they stay put at any scale
    table.insert(self.dots, event.y / self.scale)
    placed += 1
    self.panel.unsaved = true -- marks the tab; closing the panel then asks to save
    self.panel:redraw()
  end
end

-- gives what the session keeps: plain values only, such as numbers, strings and tables of them
function Marks:saveState()
  return { dots = self.dots }
end

-- saves the panel's unsaved work, when the user asks or closes it; the dots are already in the session, so it only clears the mark
function Marks:save()
  self.panel.unsaved = false
  return true
end

ecs.panel.registerType({
  name = "panel",
  title = "Marks",
  stateVersion = STATE_VERSION,

  create = Marks.create,

  draw = Marks.draw,

  event = Marks.event,

  saveState = Marks.saveState,

  save = Marks.save,
})

-- state that belongs to no panel, but to the plugin; restoreState runs before the session's panels are made
ecs.plugin.register({
  stateVersion = 1,
  saveState = function()
    return { placed = placed }
  end,
  restoreState = function(saved)
    placed = saved and saved.placed or 0
  end,
})
