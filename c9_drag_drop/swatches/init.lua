-- A palette whose colours drag onto samples, and within the palette to reorder them. A sample also takes files dropped from other applications,
-- and shows their names. While a colour is dragged over a panel that takes it, the panel shows where it will land: the palette a line between
-- its swatches, the sample a mark at the pointer.

local ecs = require("ecs")

local draw = require("draw") -- the functions of a plugin the manifest depends on

local COLORS = { "#BF616A", "#D08770", "#EBCB8B", "#A3BE8C", "#5E81AC", "#B48EAD" }
local SWATCH = 48 -- in layout units

-- the palette: one row of squares, which a colour dragged onto it reorders

-- each panel's state is an object of Palette, whose functions are methods
local Palette = {}
Palette.__index = Palette

function Palette.create(panel, saved)
  -- the palette takes its own colours, so a drag within it moves one
  panel:acceptDrops({ "swatches.color" })
  return setmetatable({ panel = panel, colors = saved and saved.colors or { table.unpack(COLORS) }, scale = 1 }, Palette)
end

-- the gap between swatches that a position is nearest to: 0 before the first, #colors after the last
function Palette:gapAt(x)
  return math.max(0, math.min(#self.colors, math.floor(x / self.scale / SWATCH + 0.5)))
end

function Palette:draw(surface)
  self.scale = surface.scale
  surface:fill(0, 0, surface.width, surface.height, "panel")

  for i, color in ipairs(self.colors) do
    draw.fill(surface, (i - 1) * SWATCH, 0, SWATCH, SWATCH, color)
  end

  if self.gap then
    draw.fill(surface, self.gap * SWATCH - 2, 0, 4, SWATCH, "text")
  end
end

function Palette:event(event)
  if event.type == "pointerDown" and event.y / self.scale < SWATCH then
    local index = math.floor(event.x / self.scale / SWATCH) + 1

    if self.colors[index] then
      -- call it while the button that was pressed on this panel is held; the type names what kind of value it carries
      self.dragged = index
      self.panel:startDrag("swatches.color", self.colors[index])
    end
  elseif event.type == "dragOver" then
    -- the core sends it at each move while a colour is over the palette, also during the palette's own drag
    self.gap = self:gapAt(event.x)
    self.panel:redraw()
  elseif event.type == "dragLeave" then
    -- the colour left the palette, or was dropped, or Escape cancelled the drag
    self.gap = nil
    self.panel:redraw()
  elseif event.type == "drop" then
    -- a colour from this palette moves to the gap, and one from another palette is added there
    local gap = self:gapAt(event.x)

    if self.dragged then
      table.remove(self.colors, self.dragged)
      gap = gap > self.dragged and gap - 1 or gap
    end

    table.insert(self.colors, gap + 1, event.value)
    self.panel:redraw()
  elseif event.type == "pointerUp" then
    -- the release comes after the drop
    self.dragged = nil
  end
end

function Palette:saveState()
  return { colors = self.colors }
end

ecs.panel.registerType({
  name = "palette",
  title = "Palette",
  stateVersion = 1,

  create = Palette.create,

  draw = Palette.draw,

  event = Palette.event,

  saveState = Palette.saveState,
})

-- the sample: one colour, the names of the files dropped last, and a mark at the pointer while a colour is over it

-- each panel's state is an object of Sample, whose functions are methods
local Sample = {}
Sample.__index = Sample

function Sample.create(panel, saved)
  -- the types the panel takes; panels that take the dragged type are outlined during a drag
  panel:acceptDrops({ "swatches.color", "file-list" })
  return setmetatable({ panel = panel, color = saved and saved.color or "#4C566A", files = {}, scale = 1 }, Sample)
end

function Sample:draw(surface)
  self.scale = surface.scale
  surface:fill(0, 0, surface.width, surface.height, self.color)

  if self.pointerX then
    surface:fill(self.pointerX - 4 * self.scale, self.pointerY - 4 * self.scale, 8 * self.scale, 8 * self.scale, "text")
  end

  for i, name in ipairs(self.files) do
    draw.text(surface, draw.font("ui"), name, 16, 16 + (i - 1) * 24, 16, "text")
  end
end

function Sample:event(event)
  -- data of a type the panel takes is over it, at each move; dragLeave says that it left, was dropped or was cancelled
  if event.type == "dragOver" then
    self.pointerX, self.pointerY = math.floor(event.x), math.floor(event.y)
    self.panel:redraw()
    return
  elseif event.type == "dragLeave" then
    self.pointerX, self.pointerY = nil, nil
    self.panel:redraw()
    return
  end

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
