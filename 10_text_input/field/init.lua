-- A one-line text field. Text comes in text events, which also carry what input methods compose, such as accented letters.
-- Keys that change the text, such as Backspace, come as keyDown events.

local ecs = require("ecs")

local draw = require("draw") -- the functions of a plugin the manifest depends on

local MARGIN, SIZE = 16, 20 -- in layout units

-- tells the core where the cursor is, in surface pixels, so an input method's window shows beside it
local function placeCursor(field)
  local width, height = draw.measure(field.text, SIZE)
  field.panel:setTextInput(true, (MARGIN + width) * field.scale, MARGIN * field.scale, 2 * field.scale, height * field.scale)
end

ecs.panel.registerType({
  name = "field.panel",
  title = "Field",
  stateVersion = 1,

  create = function(panel, saved)
    local field = { panel = panel, text = saved and saved.text or "", scale = 1 }
    placeCursor(field) -- the panel gets text events only while it has the focus and accepts text
    return field
  end,

  draw = function(field, surface)
    field.scale = surface.scale
    surface:fill(0, 0, surface.width, surface.height, draw.color("background"))
    local width = draw.text(surface, field.text, MARGIN, MARGIN, SIZE, draw.color("text"))
    local _, height = draw.measure(field.text, SIZE)
    draw.fill(surface, MARGIN + width, MARGIN, 2, height, draw.color("accent")) -- the cursor
  end,

  event = function(field, event)
    if event.type == "text" then
      field.text = field.text .. event.text
    elseif event.type == "keyDown" and event.key == "Backspace" and #field.text > 0 then
      field.text = field.text:sub(1, utf8.offset(field.text, -1) - 1) -- drops the last character, which may be several bytes
    else
      return
    end

    placeCursor(field)
    field.panel:redraw()
  end,

  saveState = function(field)
    return { text = field.text }
  end,
})
