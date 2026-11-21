-- A one-line text field. Text comes in text events, which also carry what input methods compose, such as accented letters.
-- Keys that change the text, such as Backspace, come as keyDown events.

local ecs = require("ecs")

local draw = require("draw") -- the functions of a plugin the manifest depends on

local MARGIN, SIZE = 16, 20 -- in layout units

-- each panel's state is an object of Field, whose functions are methods
local Field = {}
Field.__index = Field

-- tells the core where the cursor is, in surface pixels, so an input method's window shows beside it
function Field:placeCursor()
  -- text is measured at the scale of the surface it is drawn into, as a font's glyphs do not grow evenly with its size
  local width, height = draw.font("ui"):measure(self.text, SIZE, self.scale)
  self.panel:setTextInput(true, (MARGIN + width) * self.scale, MARGIN * self.scale, 2 * self.scale, height * self.scale)
end

function Field.create(panel, saved)
  local field = setmetatable({ panel = panel, text = saved and saved.text or "", scale = 1 }, Field)
  field:placeCursor() -- the panel gets text events only while it has the focus and accepts text
  return field
end

function Field:draw(surface)
  self.scale = surface.scale
  surface:fill(0, 0, surface.width, surface.height, "background")
  local width = draw.text(surface, draw.font("ui"), self.text, MARGIN, MARGIN, SIZE, "text")
  local _, height = draw.font("ui"):measure(self.text, SIZE, surface.scale)
  draw.fill(surface, MARGIN + width, MARGIN, 2, height, "accent") -- the cursor
end

function Field:event(event)
  if event.type == "text" then
    self.text ..= event.text
  elseif event.type == "keyDown" and event.key == "Backspace" and #self.text > 0 then
    self.text = self.text:sub(1, utf8.offset(self.text, -1) - 1) -- drops the last character, which may be several bytes
  else
    return
  end

  self:placeCursor()
  self.panel:redraw()
end

function Field:saveState()
  return { text = self.text }
end

ecs.panel.registerType({
  name = "panel",
  title = "Field",
  stateVersion = 1,

  create = Field.create,

  draw = Field.draw,

  event = Field.event,

  saveState = Field.saveState,
})
