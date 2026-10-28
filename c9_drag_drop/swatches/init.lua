-- A palette whose colours drag onto samples. A sample also takes files dropped from other applications, and shows their names.

local ecs = require("ecs")

local draw = require("draw") -- the functions of a plugin the manifest depends on

local COLORS = { "#BF616A", "#D08770", "#EBCB8B", "#A3BE8C", "#5E81AC", "#B48EAD" }
local SWATCH = 48 -- in layout units

-- the palette: one row of squares
ecs.panel.registerType({
  name = "palette",
  title = "Palette",

  create = function(panel)
    return { panel = panel, scale = 1 }
  end,

  draw = function(state, surface)
    state.scale = surface.scale
    surface:fill(0, 0, surface.width, surface.height, "background")

    for i, color in ipairs(COLORS) do
      draw.fill(surface, (i - 1) * SWATCH, 0, SWATCH, SWATCH, color)
    end
  end,

  event = function(state, event)
    if event.type ~= "pointerDown" or event.y / state.scale >= SWATCH then
      return
    end

    local color = COLORS[math.floor(event.x / state.scale / SWATCH) + 1]

    if color then
      -- call it while the button that was pressed on this panel is held; the type names what kind of value it carries
      state.panel:startDrag("swatches.color", color)
    end
  end,
})

-- the sample: one colour, and the names of the files dropped last
ecs.panel.registerType({
  name = "sample",
  title = "Sample",
  stateVersion = 1,

  create = function(panel, saved)
    -- the types the panel takes; panels that take the dragged type are outlined during a drag
    panel:acceptDrops({ "swatches.color", "file-list" })
    return { panel = panel, color = saved and saved.color or "#4C566A", files = {} }
  end,

  draw = function(state, surface)
    surface:fill(0, 0, surface.width, surface.height, state.color)

    for i, name in ipairs(state.files) do
      draw.text(surface, draw.font("ui"), name, 16, 16 + (i - 1) * 24, 16, "text")
    end
  end,

  event = function(state, event)
    if event.type ~= "drop" then
      return
    end

    if event.dataType == "swatches.color" then
      state.color = event.value
    else
      -- a "file-list" is a list of paths
      state.files = {}

      for _, path in ipairs(event.value) do
        table.insert(state.files, path:match("[^/]*$"))
      end
    end

    state.panel:redraw()
  end,

  saveState = function(state)
    return { color = state.color, files = state.files }
  end,
})
