-- A glTF model that turns, drawn as lines: the gltf standard plugin reads the model and gives its vertices and triangles, and the panel draws them.
-- A panel type with continuous = true draws every frame while it shows, and its draw gets the seconds since the last one.

local ecs = require("ecs")
local gltf = require("gltf")

local model = gltf.load(ecs.plugin.folder .. "cube.gltf")
local info = gltf.describe(model)

-- the first primitive of the first mesh: its positions, three floats each, and its triangles, three indices each, from 0
local primitive = info.meshes[1].primitives[1]
local positions = gltf.attribute(model, 1, 1, "POSITION")
local indices = gltf.indices(model, 1, 1)
local points, triangles = {}, {}

for i = 0, primitive.vertices - 1 do
  points[i] = { string.unpack("<fff", positions, i * 12 + 1) }
end

for i = 0, primitive.indices - 1, 3 do
  triangles[#triangles + 1] = { string.unpack("<I4I4I4", indices, i * 4 + 1) }
end

-- the material's colour, as ARGB
local r, g, b = table.unpack(info.materials[primitive.material].color)
local COLOR = 0xFF000000 | math.floor(r * 255) << 16 | math.floor(g * 255) << 8 | math.floor(b * 255)

-- a line of pixels from one point to another
local function line(surface, x0, y0, x1, y1)
  local steps = math.max(math.abs(x1 - x0), math.abs(y1 - y0), 1)

  for step = 0, steps do
    surface:setPixel(math.floor(x0 + (x1 - x0) * step / steps + 0.5), math.floor(y0 + (y1 - y0) * step / steps + 0.5), COLOR)
  end
end

ecs.panel.registerType({
  name = "model.panel",
  title = "Model",
  continuous = true,

  create = function()
    return { angle = 0, drawn = 0 }
  end,

  draw = function(view, surface, seconds)
    view.angle = view.angle + seconds * 0.8
    view.drawn = view.drawn + 1
    surface:fill(0, 0, surface.width, surface.height, 0xFF101418)

    -- each point turns around the vertical axis, leans towards the viewer, and is drawn with a little perspective
    local cos, sin = math.cos(view.angle), math.sin(view.angle)
    local scale = math.min(surface.width, surface.height) * 0.3
    local projected = {}

    for i, point in pairs(points) do
      local x, y, z = point[1] * cos - point[3] * sin, point[2], point[1] * sin + point[3] * cos
      y, z = y * 0.94 - z * 0.34, y * 0.34 + z * 0.94
      local depth = 4 / (z + 5)
      projected[i] = { surface.width / 2 + x * scale * depth, surface.height / 2 - y * scale * depth }
    end

    for _, triangle in ipairs(triangles) do
      for corner = 1, 3 do
        local a, b = projected[triangle[corner]], projected[triangle[corner % 3 + 1]]
        line(surface, a[1], a[2], b[1], b[2])
      end
    end
  end,

  -- how many frames it drew, so the test can see it draws every frame
  saveState = function(view)
    return { drawn = view.drawn, triangles = #triangles, vertices = primitive.vertices }
  end,
})
