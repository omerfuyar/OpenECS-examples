-- A glTF model that turns, drawn as lines: the gltf standard plugin reads the model and gives its vertices and triangles, and the draw plugin draws their edges.
-- A panel type with continuous = true draws every frame while it shows, and its draw gets the seconds since the last one.

local ecs = require("ecs")
local gltf = require("gltf")
local draw = require("draw")
local image = require("image")

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

-- a .glb file holds its pictures inside it: the badge's material names its image by number, gltf.image gives that image's bytes, and image.decode makes a picture of them
local badge = gltf.load(ecs.plugin.folder .. "badge.glb")
local badgeInfo = gltf.describe(badge)
local badgeImage = badgeInfo.images[badgeInfo.materials[1].image]
local TEXTURE = image.decode(gltf.image(badge, badgeInfo.materials[1].image), 1)
local TEXTURE_WIDTH, TEXTURE_HEIGHT = draw.imageSize(TEXTURE)

-- the badge's animation turns it, moves it and grows it; gltf.pose gives each node's matrix at a time of it, 16 floats column by column
local SPIN = badgeInfo.animations[1]

-- the badge node's turn in degrees, its move to the right and its size, at a time of the animation
local function badgeAt(seconds)
  local m = { string.unpack("<ffffffffffffffff", gltf.pose(badge, 1, seconds)) }
  return math.deg(math.atan(m[2], m[1])), m[13], math.sqrt(m[1] * m[1] + m[2] * m[2] + m[3] * m[3])
end

-- an arm whose skin bends it: its vertices follow two joints, the root and the tip, and its animation turns the tip a quarter turn in a second;
-- gltf.skin gives the vertices where the joints move them at a time of the animation, three floats each
local arm = gltf.load(ecs.plugin.folder .. "arm.glb")
local armInfo = gltf.describe(arm)
local BEND = armInfo.animations[1]
local ARM_SKIN = armInfo.nodes[1].skin
local ARM_VERTICES = armInfo.meshes[1].primitives[1].vertices
local armIndices = gltf.indices(arm, 1, 1)
local armEdges = {}

for i = 0, armInfo.meshes[1].primitives[1].indices - 1, 3 do
  local a, b, c = string.unpack("<I4I4I4", armIndices, i * 4 + 1)
  armEdges[#armEdges + 1] = string.pack("=I4I4I4I4I4I4", a, b, b, c, c, a)
end

local ARM_EDGES = table.concat(armEdges)

-- a vertex of the arm, from 1, at a time of its animation
local function armAt(vertex, seconds)
  return { string.unpack("<fff", gltf.skin(arm, 1, 1, ARM_SKIN, 1, seconds), (vertex - 1) * 12 + 1) }
end

ecs.panel.registerType({
  name = "panel",
  title = "Model",
  continuous = true,

  create = function()
    return { angle = 0, drawn = 0, time = 0 }
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

    -- the badge's texture near the top left corner, at four times its size, turned, moved and grown as its animation says; the animation goes round
    view.time = (view.time + seconds) % SPIN.duration
    local turn, right, grow = badgeAt(view.time)
    local size = TEXTURE_WIDTH * 4 * grow
    -- the arm on the right, bending and straightening again: the animation's time goes there and back
    local bend = view.time % (2 * BEND.duration)
    local skinned = gltf.skin(arm, 1, 1, ARM_SKIN, 1, bend <= BEND.duration and bend or 2 * BEND.duration - bend)
    local armPoints = {}

    for i = 0, ARM_VERTICES - 1 do
      local x, y = string.unpack("<ff", skinned, i * 12 + 1)
      armPoints[i + 1] = string.pack("=ff", width - 160 + x * 70, height - 40 - y * 70)
    end

    draw.lines(surface, table.concat(armPoints), ARM_EDGES, 1, "#E0A040")
    draw.imageTransformed(surface, TEXTURE, 100 + right * 60 - size / 2, 100 - size / 2, size, size, -turn, "#FFFFFF")
  end,

  -- how many frames it drew, so the test can see it draws every frame
  saveState = function(view)
    return { drawn = view.drawn, triangles = TRIANGLES, vertices = primitive.vertices, texture = { mimeType = badgeImage.mimeType, file = badgeImage.file, width = TEXTURE_WIDTH, height = TEXTURE_HEIGHT },
      spin = { name = SPIN.name, duration = SPIN.duration, early = { badgeAt(0.5) }, late = { badgeAt(2.5) }, middle = { badgeAt(2) } },
      arm = { rest = armAt(6, 0), top = armAt(6, 1), middle = armAt(4, 1), joints = #armInfo.skins[ARM_SKIN].joints } }
  end,
})
