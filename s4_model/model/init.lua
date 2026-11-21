-- A glTF model that turns, drawn as lines: the gltf standard plugin reads the model and gives its vertices and triangles, and the draw plugin draws their edges.
-- A panel type with continuous = true draws every frame while it shows, and its draw gets the seconds since the last one.

local ecs = require("ecs")
local ffi = require("ffi")
local gltf = require("gltf")
local draw = require("draw")
local image = require("image")

local model = gltf.load(ecs.plugin.folder .. "cube.gltf")
local info = assert(model:describe())

-- the first primitive of the first mesh: its positions, three floats each, and its triangles, three indices each, from 0
local primitive = info.meshes[1].primitives[1]
local positions = model:attribute(1, 1, "POSITION")
local indices = model:indices(1, 1)
local points = {}

-- the FFI reads the bytes as C arrays: a pointer into a string is valid while the string is
local xyz = ffi.cast("const float *", positions)

for i = 0, primitive.vertices - 1 do
  points[i + 1] = { xyz[i * 3], xyz[i * 3 + 1], xyz[i * 3 + 2] }
end

-- each triangle's three edges, as pairs of point numbers from 0, which draw.lines takes as 32-bit integers
local function edgesOf(indexBytes, count)
  local corners, edges = ffi.cast("const uint32_t *", indexBytes), ffi.new("uint32_t[?]", count * 2)

  for i = 0, count - 1, 3 do
    local a, b, c = corners[i], corners[i + 1], corners[i + 2]
    edges[i * 2], edges[i * 2 + 1], edges[i * 2 + 2], edges[i * 2 + 3], edges[i * 2 + 4], edges[i * 2 + 5] = a, b, b, c, c, a
  end

  return ffi.string(edges, ffi.sizeof(edges))
end

local EDGES = edgesOf(indices, primitive.indices)
local TRIANGLES = primitive.indices / 3

-- the material's colour, as a text
local r, g, b = table.unpack(info.materials[primitive.material].color)
local COLOR = ("#%02X%02X%02X"):format(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))

-- a .glb file holds its pictures inside it: the badge's material names its image by number, the model's image gives that image's bytes, and image.decode makes a picture of them
local badge = gltf.load(ecs.plugin.folder .. "badge.glb")
local badgeInfo = assert(badge:describe())
local badgeImage = badgeInfo.images[badgeInfo.materials[1].image]
local TEXTURE = image.decode(badge:image(badgeInfo.materials[1].image), 1)
local TEXTURE_WIDTH, TEXTURE_HEIGHT = TEXTURE:size()

-- the badge's animation turns it, moves it and grows it; pose gives each node's matrix at a time of it, 16 floats column by column
local SPIN = badgeInfo.animations[1]

-- the badge node's turn in degrees, its move to the right and its size, at a time of the animation
local function badgeAt(seconds)
  local pose = badge:pose(1, seconds)
  local m = ffi.cast("const float *", pose)
  return math.deg(math.atan2(m[1], m[0])), m[12], math.sqrt(m[0] * m[0] + m[1] * m[1] + m[2] * m[2])
end

-- an arm whose skin bends it: its vertices follow two joints, the root and the tip, and its animation turns the tip a quarter turn in a second;
-- skin gives the vertices where the joints move them at a time of the animation, three floats each
local arm = gltf.load(ecs.plugin.folder .. "arm.glb")
local armInfo = assert(arm:describe())
local BEND = armInfo.animations[1]
local ARM_SKIN = assert(armInfo.nodes[1].skin)
local ARM_VERTICES = armInfo.meshes[1].primitives[1].vertices
local ARM_EDGES = edgesOf(arm:indices(1, 1), armInfo.meshes[1].primitives[1].indices)

-- a vertex of the arm, from 1, at a time of its animation
local function armAt(vertex, seconds)
  local skinned = arm:skin(1, 1, ARM_SKIN, 1, seconds)
  local xyz = ffi.cast("const float *", skinned) + (vertex - 1) * 3
  return { xyz[0], xyz[1], xyz[2] }
end

ecs.panel.registerType({
  name = "panel",
  title = "Model",
  continuous = true,

  create = function()
    return { angle = 0, drawn = 0, time = 0 }
  end,

  draw = function(state, surface, seconds)
    state.angle += seconds * 0.8
    state.drawn += 1
    surface:fill(0, 0, surface.width, surface.height, "#101418")

    -- each point turns around the vertical axis, leans towards the viewer, and is drawn with a little perspective, in layout units
    local cos, sin = math.cos(state.angle), math.sin(state.angle)
    local width, height = surface.width / surface.scale, surface.height / surface.scale
    local scale = math.min(width, height) * 0.3
    local projected = ffi.new("float[?]", #points * 2)

    for i, point in ipairs(points) do
      local x, y, z = point[1] * cos - point[3] * sin, point[2], point[1] * sin + point[3] * cos
      y, z = y * 0.94 - z * 0.34, y * 0.34 + z * 0.94
      local depth = 4 / (z + 5)
      projected[i * 2 - 2], projected[i * 2 - 1] = width / 2 + x * scale * depth, height / 2 - y * scale * depth
    end

    draw.lines(surface, ffi.string(projected, ffi.sizeof(projected)), EDGES, 1, COLOR)

    -- the badge's texture near the top left corner, at four times its size, turned, moved and grown as its animation says; the animation goes round
    state.time = (state.time + seconds) % SPIN.duration
    local turn, right, grow = badgeAt(state.time)
    local size = TEXTURE_WIDTH * 4 * grow
    -- the arm on the right, bending and straightening again: the animation's time goes there and back
    local bend = state.time % (2 * BEND.duration)
    local skinned = arm:skin(1, 1, ARM_SKIN, 1, bend <= BEND.duration and bend or 2 * BEND.duration - bend)
    local xyz = ffi.cast("const float *", skinned)
    local armPoints = ffi.new("float[?]", ARM_VERTICES * 2)

    for i = 0, ARM_VERTICES - 1 do
      armPoints[i * 2], armPoints[i * 2 + 1] = width - 160 + xyz[i * 3] * 70, height - 40 - xyz[i * 3 + 1] * 70
    end

    draw.lines(surface, ffi.string(armPoints, ffi.sizeof(armPoints)), ARM_EDGES, 1, "#E0A040")
    draw.imageTransformed(surface, TEXTURE, 100 + right * 60 - size / 2, 100 - size / 2, size, size, -turn, "#FFFFFF")
  end,

  -- how many frames it drew, so the test can see it draws every frame
  saveState = function(state)
    return { drawn = state.drawn, triangles = TRIANGLES, vertices = primitive.vertices, texture = { mimeType = badgeImage.mimeType, file = badgeImage.file, width = TEXTURE_WIDTH, height = TEXTURE_HEIGHT },
      spin = { name = SPIN.name, duration = SPIN.duration, early = { badgeAt(0.5) }, late = { badgeAt(2.5) }, middle = { badgeAt(2) } },
      arm = { rest = armAt(6, 0), top = armAt(6, 1), middle = armAt(4, 1), joints = #armInfo.skins[ARM_SKIN].joints } }
  end,
})
