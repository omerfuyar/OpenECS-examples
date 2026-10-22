-- A glTF model drawn on the GPU with shaders of its own. The gltf standard plugin reads its vertices, normals and triangles; they go to the GPU once,
-- as a vertex buffer and an index buffer, and each frame the gpu standard plugin draws them with a pipeline: a vertex shader that moves and sees
-- each vertex, and a fragment shader that lights each pixel. A depth texture keeps the near side in front, so nothing is sorted in Lua.
-- The panel also draws shapes, before and after the model: a shadow under it, as a mesh, and a line at the bottom.
-- A label follows a point of the ring, drawn with shaders of its own from the glyphs that gpu.glyphs gives, at the point's depth, so the ring hides it as it passes behind.
-- Drag to turn the model, and turn the wheel to come nearer or go back; let go, and it turns on by itself.

local ecs = require("ecs")
local draw = require("draw")
local gltf = require("gltf")
local gpu = require("gpu")
local cglm = require("cglm")

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

-- the shaders, in GLSL in the shaders folder: gpu compiles them to SPIR-V, which Vulkan's drivers take, and turns that into DXBC for Direct3D 12's;
-- it counts each shader's uniform blocks and textures itself
local function read(name)
  local file = assert(io.open(ecs.plugin.folder .. "shaders/" .. name, "rb"))
  local source = file:read("a")
  file:close()
  return source
end

local pipeline = gpu.pipeline({
  vertex = gpu.shader({ stage = "vertex", glsl = read("torus.vert") }),
  fragment = gpu.shader({ stage = "fragment", glsl = read("torus.frag") }),
  attributes = { "float3", "float3" },
  depth = true,
})

-- gpu.compile gives the SPIR-V of GLSL, or why it does not compile, as an editor of shaders would show it
local COMPILED = #gpu.compile(read("torus.frag"), "fragment")
local _, COMPILE_ERROR = gpu.compile("#version 450\nvoid main() { missing = 1.0; }", "fragment")

-- the label: each vertex of a glyph is x and y in pixels and u and v in a texture of glyphs, four floats, and blends by the glyph's alpha
local labelPipeline = gpu.pipeline({
  vertex = gpu.shader({ stage = "vertex", glsl = read("label.vert") }),
  fragment = gpu.shader({ stage = "fragment", glsl = read("label.frag") }),
  attributes = { "float4" },
  depth = true,
  blend = "alpha",
})

local LABEL, LABEL_SIZE = "glTF torus", 18
local LABEL_POINT = cglm.vec4(1.6, 0, 0, 1) -- just outside the ring, which is 1.42 wide from its centre
local font = draw.font("ui")

-- the label's glyphs at a scale, as buffers on the GPU; made again when the scale changes, such as on another display
local label = nil

local function labelAt(scale)
  if label and label.scale == scale then
    return label
  end

  local glyphs = gpu.glyphs(font, LABEL, LABEL_SIZE * scale)
  label = { scale = scale, height = glyphs and glyphs.height or 0, parts = {} }

  for _, part in ipairs(glyphs and glyphs.parts or {}) do
    label.parts[#label.parts + 1] = { atlas = part.atlas, count = part.count, vertices = gpu.buffer("vertex", part.vertices), indices = gpu.buffer("index", part.indices) }
  end

  return label
end

-- the material's colour, the way the light goes, from the top left and from in front, and the camera's place, as the fragment shader's uniforms
local BASE = info.materials[primitive.material].color

-- cglm's matrices are 16 floats column by column, as the shaders read them, and its vectors are floats too; both are strings,
-- so the uniforms are the matrices and vectors joined together
local X, Y, Z = cglm.vec3(1, 0, 0), cglm.vec3(0, 1, 0), cglm.vec3(0, 0, 1)

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
    return { turn = 0.6, tilt = 0.3, distance = 5.5, drawn = 0, dragging = nil, labelParts = 0 }
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
      local modelMatrix = cglm.mat4Mul(cglm.rotateMake(view.tilt, X), cglm.mat4Mul(cglm.rotateMake(view.turn, Y), cglm.rotateMake(math.rad(60), Z)))
      local camera = cglm.translateMake(cglm.vec3(0, 0, -view.distance))
      -- a perspective that sees down -z from the camera, with depth from 0, near, to 1, far, as SDL's GPU API takes it
      local viewProjection = cglm.mat4Mul(cglm.perspective(math.rad(45), width / height, 0.1, 50), camera)

      gpu.draw(surface, pipeline, {
        vertices = vertexBuffer,
        indices = indexBuffer,
        vertexUniforms = modelMatrix .. viewProjection,
        fragmentUniforms = cglm.vec4(BASE[1], BASE[2], BASE[3], 1) .. cglm.vec4(0.45, -0.65, -0.6, 0) .. cglm.vec4(0, 0, view.distance, 1),
      })

      -- the label starts a little to the right of its point, with its line's middle at the point's height
      if labelPipeline then
        local glyphs = labelAt(surface.scale)
        local screen = cglm.vec4(surface.width, surface.height, 10 * surface.scale, -glyphs.height / 2)

        for _, part in ipairs(glyphs.parts) do
          gpu.draw(surface, labelPipeline, {
            vertices = part.vertices,
            indices = part.indices,
            count = part.count,
            atlas = part.atlas,
            vertexUniforms = modelMatrix .. viewProjection .. LABEL_POINT .. screen,
            fragmentUniforms = cglm.vec4(1, 1, 1, 1),
          })
        end

        view.labelParts = #glyphs.parts
      end
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
      view.distance = math.max(2, math.min(12, view.distance - event.scrollY * 0.5))
    end
  end,

  -- what the test checks: the model's size, how many frames it drew, where the camera is, and what gpu.compile gave
  saveState = function(view)
    return { vertices = VERTICES, triangles = TRIANGLES, drawn = view.drawn, turn = view.turn, distance = view.distance, pipeline = pipeline ~= nil, labelParts = view.labelParts,
      compiled = COMPILED, compileError = COMPILE_ERROR }
  end,
})
