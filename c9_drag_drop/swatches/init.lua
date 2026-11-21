-- A palette whose colours drag onto samples. A sample also takes files dropped from other applications, and shows their names.

local ecs = require("ecs")

local draw = require("draw") -- the functions of a plugin the manifest depends on

local COLORS = { "#BF616A", "#D08770", "#EBCB8B", "#A3BE8C", "#5E81AC", "#B48EAD" }
local SWATCH = 48 -- in layout units

-- the palette: one row of squares

-- each panel's state is an object of Palette, whose functions are methods
local Palette = {}
Palette.__index = Palette

function Palette.create(panel)
  return setmetatable({ panel = panel, scale = 1 }, Palette)
end

function Palette:draw(surface)
  self.scale = surface.scale
  surface:fill(0, 0, surface.width, surface.height, "background")

  for i, color in ipairs(COLORS) do
    draw.fill(surface, (i - 1) * SWATCH, 0, SWATCH, SWATCH, color)
  end
end

function Palette:event(event)
  if event.type ~= "pointerDown" or event.y / self.scale >= SWATCH then
    return
  end

  local color = COLORS[math.floor(event.x / self.scale / SWATCH) + 1]

  if color then
    -- call it while the button that was pressed on this panel is held; the type names what kind of value it carries
    self.panel:startDrag("swatches.color", color)
  end
end

ecs.panel.registerType({
  name = "palette",
  title = "Palette",

  create = Palette.create,

  draw = Palette.draw,

  event = Palette.event,
})

-- the sample: one colour, and the names of the files dropped last

-- each panel's state is an object of Sample, whose functions are methods
local Sample = {}
Sample.__index = Sample

function Sample.create(panel, saved)
  -- the types the panel takes; panels that take the dragged type are outlined during a drag
  panel:acceptDrops({ "swatches.color", "file-list" })
  return setmetatable({ panel = panel, color = saved and saved.color or "#4C566A", files = {} }, Sample)
end

function Sample:draw(surface)
  surface:fill(0, 0, surface.width, surface.height, self.color)

  for i, name in ipairs(self.files) do
    draw.text(surface, draw.font("ui"), name, 16, 16 + (i - 1) * 24, 16, "text")
  end
end

function Sample:event(event)
  if event.type ~= "drop" then
    return
  end

  if event.dataType == "swatches.color" then
    self.color = event.value
  else
    -- a "file-list" is a list of paths
    self.files = {}

    for _, path in ipairs(event.value) do
      table.insert(self.files, path:match("[^/]*$"))
    end
  end

  self.panel:redraw()
end

function Sample:saveState()
  return { color = self.color, files = self.files }
end

ecs.panel.registerType({
  name = "sample",
  title = "Sample",
  stateVersion = 1,

  create = Sample.create,

  draw = Sample.draw,

  event = Sample.event,

  saveState = Sample.saveState,
})
