-- A glTF model that turns, drawn as lines: the gltf standard plugin reads the model and gives its vertices and triangles, and the draw plugin draws their edges.
-- A panel type with continuous = true draws every frame while it shows, and its draw gets the seconds since the last one.

local ecs = require("ecs")
local gltf = require("gltf")
local draw = require("draw")

local model = gltf.load(ecs.plugin.folder .. "cube.gltf")
local info = gltf.describe(model)

-- the first primitive of the first mesh: its positions, three floats each, and its triangles, three indices each, from 0
local primitive = info.meshes[1].primitives[1]
local positions = gltf.attribute(model, 1, 1, "POSITION")
local indices = gltf.indices(model, 1, 1)
local points, edges = {}, {}

for i = 0, primitive.vertices - 1 do
  points[i + 1] = { string.unpack("<fff", positions, i * 12 + 1) }
end

-- each triangle's three edges, as pairs of point numbers from 0, which draw.lines takes as 32-bit integers
for i = 0, primitive.indices - 1, 3 do
  local a, b, c = string.unpack("<I4I4I4", indices, i * 4 + 1)
  edges[#edges + 1] = string.pack("=I4I4I4I4I4I4", a, b, b, c, c, a)
end

local EDGES = table.concat(edges)
local TRIANGLES = primitive.indices // 3

-- the material's colour, as a text
local r, g, b = table.unpack(info.materials[primitive.material].color)
local COLOR = ("#%02X%02X%02X"):format(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))

ecs.panel.registerType({
  name = "panel",
  title = "Model",
  continuous = true,

  create = function()
    return { angle = 0, drawn = 0 }
  end,

  draw = function(view, surface, seconds)
    view.angle = view.angle + seconds * 0.8
    view.drawn = view.drawn + 1
    surface:fill(0, 0, surface.width, surface.height, "#101418")

    -- each point turns around the vertical axis, leans towards the viewer, and is drawn with a little perspective, in layout units
    local cos, sin = math.cos(view.angle), math.sin(view.angle)
    local width, height = surface.width / surface.scale, surface.height / surface.scale
    local scale = math.min(width, height) * 0.3
    local projected = {}

    for i, point in ipairs(points) do
      local x, y, z = point[1] * cos - point[3] * sin, point[2], point[1] * sin + point[3] * cos
      y, z = y * 0.94 - z * 0.34, y * 0.34 + z * 0.94
      local depth = 4 / (z + 5)
      projected[i] = string.pack("=ff", width / 2 + x * scale * depth, height / 2 - y * scale * depth)
    end

    draw.lines(surface, table.concat(projected), EDGES, 1, COLOR)
  end,

  -- how many frames it drew, so the test can see it draws every frame
  saveState = function(view)
    return { drawn = view.drawn, triangles = TRIANGLES, vertices = primitive.vertices }
  end,
})
