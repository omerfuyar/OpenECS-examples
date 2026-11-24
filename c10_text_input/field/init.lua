-- A one-line text field. Text comes in text events, which also carry what input methods compose, such as accented letters.
-- Keys that change the text, such as Backspace, come as keyDown events.

local ecs = require("ecs")

local draw = require("draw") -- the functions of a plugin the manifest depends on

local MARGIN, SIZE = 16, 20 -- in layout units
local HINT = "Type some words" -- shown in italic while the field is empty

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
  surface:fill(0, 0, surface.width, surface.height, "panel")
  local width = draw.text(surface, draw.font("ui"), self.text, MARGIN, MARGIN, SIZE, "text")

  -- a font in a style comes from draw.styledFont, and draw.font is the font itself
  if self.text == "" then
    draw.text(surface, draw.styledFont("ui", "italic"), HINT, MARGIN, MARGIN, SIZE, "textDim")
  end

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

-- the hint's width is saved measured whole and word by word, as ui lays out a text of spans: draw measures text by where each
-- glyph starts the next, so the two are the same, in italic too, whose slanted glyphs reach past that
function Field:saveState()
  local italic = draw.styledFont("ui", "italic")
  local words = 0

  for word, blank in HINT:gmatch("(%S+)(%s*)") do
    words += italic:measure(word, SIZE, 1) + (blank ~= "" and italic:measure(blank, SIZE, 1) or 0)
  end

  return { text = self.text, hint = italic:measure(HINT, SIZE, 1), hintByWords = words }
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
