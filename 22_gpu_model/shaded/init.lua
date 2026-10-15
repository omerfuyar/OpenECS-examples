-- A glTF model drawn on the GPU with shaders of its own. The gltf standard plugin reads its vertices, normals and triangles; they go to the GPU once,
-- as a vertex buffer and an index buffer, and each frame the gpu standard plugin draws them with a pipeline: a vertex shader that moves and sees
-- each vertex, and a fragment shader that lights each pixel. A depth texture keeps the near side in front, so nothing is sorted in Lua.
-- The panel also draws shapes, before and after the model: a shadow under it, as a mesh, and a line at the bottom.
-- Drag to turn the model, and turn the wheel to come nearer or go back; let go, and it turns on by itself.

local ecs = require("ecs")
local gltf = require("gltf")
local gpu = require("gpu")

local BACKGROUND = "#101418"

-- the first primitive of the first mesh: its positions and its normals, three floats each, and its triangles, three indices each, from 0
local model = gltf.load(ecs.plugin.folder .. "torus.gltf")
local info = assert(model:describe())
local primitive = info.meshes[1].primitives[1]
local VERTICES, TRIANGLES = primitive.vertices, primitive.indices // 3

-- each call of attribute or indices replaces the buffer of the last one, so each is copied before the next
local positions = model:attribute(1, 1, "POSITION")
local normals = model:attribute(1, 1, "NORMAL")
local vertices = {}

-- a vertex is its position and its normal, six floats, as the pipeline's attributes say
for i = 0, VERTICES - 1 do
  vertices[i + 1] = positions:sub(i * 12 + 1, i * 12 + 12) .. normals:sub(i * 12 + 1, i * 12 + 12)
end

-- nil without a GPU renderer; the panel then draws only its shapes
local vertexBuffer = gpu.buffer("vertex", table.concat(vertices))
local indexBuffer = gpu.buffer("index", model:indices(1, 1))

-- the shaders, compiled from torus.vert and torus.frag in the shaders folder to SPIR-V, which Vulkan's drivers take
local function read(name)
  local file = assert(io.open(ecs.plugin.folder .. "shaders/" .. name, "rb"))
  local bytes = file:read("a")
  file:close()
  return bytes
end

local pipeline = gpu.pipeline({
  vertex = gpu.shader({ stage = "vertex", spirv = read("torus.vert.spv"), uniforms = 1 }),
  fragment = gpu.shader({ stage = "fragment", spirv = read("torus.frag.spv"), uniforms = 1 }),
  attributes = { "float3", "float3" },
  depth = true,
})

-- the material's colour, the way the light goes, from the top left and from in front, and the camera's place, as the fragment shader's uniforms
local BASE = info.materials[primitive.material].color

-- 4 by 4 matrices, 16 floats column by column, as the shaders read them
local function multiply(a, b)
  local m = {}

  for column = 0, 3 do
    for row = 1, 4 do
      local sum = 0

      for k = 0, 3 do
        sum = sum + a[k * 4 + row] * b[column * 4 + k + 1]
      end

      m[column * 4 + row] = sum
    end
  end

  return m
end

local function rotation(axis, angle)
  local c, s = math.cos(angle), math.sin(angle)

  if axis == "x" then
    return { 1, 0, 0, 0, 0, c, s, 0, 0, -s, c, 0, 0, 0, 0, 1 }
  elseif axis == "y" then
    return { c, 0, -s, 0, 0, 1, 0, 0, s, 0, c, 0, 0, 0, 0, 1 }
  end

  return { c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 }
end

-- a perspective that sees down -z from the camera, with depth from 0, near, to 1, far, as SDL's GPU API takes it
local function perspective(fov, aspect, near, far)
  local f = 1 / math.tan(fov / 2)
  return { f / aspect, 0, 0, 0, 0, f, 0, 0, 0, 0, far / (near - far), -1, 0, 0, near * far / (near - far), 0 }
end

local function pack(...)
  local floats = {}

  for _, matrix in ipairs({ ... }) do
    for _, value in ipairs(matrix) do
      floats[#floats + 1] = value
    end
  end

  return string.pack("<" .. ("f"):rep(#floats), table.unpack(floats))
end

-- the shadow under the model: a fan of triangles, dark in the middle and clear at its edge, which gpu's mesh blends
local function shadow(x, y, width, height)
  local points, colors, indices = { string.pack("=ff", x, y) }, { string.pack("=I4", 0x90000000) }, {}
  local SIDES = 32

  for i = 0, SIDES - 1 do
    local angle = i / SIDES * 2 * math.pi
    points[#points + 1] = string.pack("=ff", x + math.cos(angle) * width / 2, y + math.sin(angle) * height / 2)
    colors[#colors + 1] = string.pack("=I4", 0x00000000)
    indices[#indices + 1] = string.pack("=I4I4I4", 0, i + 1, (i + 1) % SIDES + 1)
  end

  return table.concat(points), table.concat(colors), table.concat(indices)
end

ecs.panel.registerType({
  name = "panel",
  title = "Shaded model",
  surface = "gpu",
  continuous = true,

  create = function()
    return { turn = 0.6, tilt = 0.3, distance = 5.5, drawn = 0, dragging = nil }
  end,

  draw = function(view, surface, seconds)
    view.drawn = view.drawn + 1

    if not view.dragging then
      view.turn = view.turn + seconds * 0.7
    end

    local width, height = surface.width / surface.scale, surface.height / surface.scale
    gpu.clear(surface, BACKGROUND)
    gpu.mesh(surface, shadow(width / 2, height * 0.85, math.min(width, height) * 0.9, math.min(width, height) * 0.12))

    -- the ring leans on its side, so it tumbles as it turns, then the drag's turn and tilt move it; the camera is in front of it, at its distance
    if pipeline and vertexBuffer and indexBuffer then
      local modelMatrix = multiply(rotation("x", view.tilt), multiply(rotation("y", view.turn), rotation("z", math.rad(60))))
      local camera = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, -view.distance, 1 }
      local viewProjection = multiply(perspective(math.rad(45), width / height, 0.1, 50), camera)

      gpu.draw(surface, pipeline, {
        vertices = vertexBuffer,
        indices = indexBuffer,
        vertexUniforms = pack(modelMatrix, viewProjection),
        fragmentUniforms = pack({ BASE[1], BASE[2], BASE[3], 1 }, { 0.45, -0.65, -0.6, 0 }, { 0, 0, view.distance, 1 }),
      })
    end

    -- shapes drawn after the model go over it
    gpu.line(surface, width * 0.1, height - 12, width * 0.9, height - 12, 2, "accent")
  end,

  -- a drag turns and tilts the model; the wheel moves it nearer or farther
  event = function(view, event)
    if event.type == "pointerDown" and event.button == 1 then
      view.dragging = { x = event.x, y = event.y }
    elseif event.type == "pointerUp" then
      view.dragging = nil
    elseif event.type == "pointerMove" and view.dragging then
      view.turn = view.turn + (event.x - view.dragging.x) * 0.01
      view.tilt = math.max(-1.5, math.min(1.5, view.tilt + (event.y - view.dragging.y) * 0.01))
      view.dragging = { x = event.x, y = event.y }
    elseif event.type == "wheel" then
      view.distance = math.max(2, math.min(12, view.distance - event.wheelY * 0.5))
    end
  end,

  -- what the test checks: the model's size, how many frames it drew, and where the camera is
  saveState = function(view)
    return { vertices = VERTICES, triangles = TRIANGLES, drawn = view.drawn, turn = view.turn, distance = view.distance, pipeline = pipeline ~= nil }
  end,
})
