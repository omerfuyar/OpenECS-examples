-- Two panel types and a setting. The panel list (Alt+W, then N) finds the panel types, and the settings window (Alt+W, then ",") changes the setting.

local ecs = require("ecs")
local draw = require("draw")

local shown = {} -- the title of every open panel, by its handle

-- the settings window lists the setting with its description, and checks what the user types against its type
ecs.settings.declare({
  name = "color",
  type = "color",
  description = "Colour of the shapes",
  default = "#A3BE8C",
  changed = function(color)
    for panel, title in pairs(shown) do
      panel.title = title .. ", " .. color
      panel:redraw()
    end
  end,
})

-- registers a panel type that draws one shape; the panel list shows its title and name
local function shape(localName, title, drawShape)
  ecs.panel.registerType({
    name = localName,
    title = title,
    create = function(panel)
      -- the tab shows the colour, so the user sees the setting change
      shown[panel] = title
      panel.title = title .. ", " .. ecs.settings.get("shapes.color")
      return { panel = panel }
    end,
    destroy = function(state)
      shown[state.panel] = nil
    end,
    draw = function(_, surface)
      surface:fill(0, 0, surface.width, surface.height, "#2E3440")
      drawShape(surface, ecs.settings.get("shapes.color"))
    end,
  })
end

-- sizes are in layout units, which draw turns into the surface's pixels
local function middle(surface)
  local width, height = surface.width / surface.scale, surface.height / surface.scale
  local size = math.min(width, height) / 2
  return (width - size) / 2, (height - size) / 2, size
end

shape("square", "Square", function(surface, color)
  local x, y, size = middle(surface)
  draw.fill(surface, x, y, size, size, color)
end)

shape("frame", "Frame", function(surface, color)
  local x, y, size = middle(surface)
  draw.outline(surface, x, y, size, size, 4, color)
end)
