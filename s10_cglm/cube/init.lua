-- A cube's edges, turned and seen in perspective: the cglm standard plugin makes the matrices, with cglm's functions, and the draw plugin draws the lines.
-- cglm's vectors and matrices are buffers of floats, Lua strings, so a matrix goes into a shader's uniforms as it is, as s9_gpu_model's do.
-- Its functions are named as cglm's, without glm_: glm_mat4_mul is cglm.mat4Mul, so cglm's documentation tells what each does.

local ecs = require("ecs")
local cglm = require("cglm")
local draw = require("draw")

-- the cube's corners, from -1 to 1 on each axis, and its twelve edges as pairs of corners from 0, which draw.lines takes as 32-bit integers
local CORNERS = {}

for i = 0, 7 do
  CORNERS[i + 1] = cglm.vec3(i & 1 == 0 and -1 or 1, i & 2 == 0 and -1 or 1, i & 4 == 0 and -1 or 1)
end

local EDGES = string.pack("=" .. ("I4"):rep(24), 0, 1, 2, 3, 4, 5, 6, 7, 0, 2, 1, 3, 4, 6, 5, 7, 0, 4, 1, 5, 2, 6, 3, 7)

local UP = cglm.vec3(0, 1, 0)

-- the camera stands up and in front, and looks at the cube's centre; the view is square, so the cube keeps its shape in any panel
local CAMERA = cglm.lookat(cglm.vec3(0, 2, 5), cglm.vec3(0, 0, 0), UP)
local PROJECTION = cglm.perspective(math.rad(45), 1, 0.1, 50)

-- the matrix that takes a corner to the view: it turns the cube around the vertical axis and leans it, then the camera and the perspective see it.
-- mat4Mul(m1, m2) does m2, then m1, so the matrices read from the last one done
local function matrixAt(turn)
  local model = cglm.mat4Mul(cglm.rotateMake(turn, UP), cglm.rotateMake(0.4, cglm.vec3(1, 0, 0)))
  return cglm.mat4Mul(PROJECTION, cglm.mat4Mul(CAMERA, model))
end

-- a corner in a view from 0 to 1 each way, from its bottom left, as cglm's project gives it
local UNIT = cglm.vec4(0, 0, 1, 1)

local function project(matrix, corner)
  local x, y = cglm.components(cglm.project(corner, matrix, UNIT))
  return x, y
end

ecs.panel.registerType({
  name = "panel",
  title = "Cube",

  create = function(panel)
    return { panel = panel, turn = 0.6, dragging = nil, drawn = 0 }
  end,

  draw = function(state, surface)
    state.drawn = state.drawn + 1
    local width, height = surface.width / surface.scale, surface.height / surface.scale
    draw.fill(surface, 0, 0, width, height, "#101418")

    -- the square view in the middle of the panel, whose y goes down
    local side = math.min(width, height)
    local left, top = (width - side) / 2, (height - side) / 2
    local matrix = matrixAt(state.turn)
    local points = {}

    for i, corner in ipairs(CORNERS) do
      local x, y = project(matrix, corner)
      points[i] = string.pack("=ff", left + x * side, top + (1 - y) * side)
    end

    draw.lines(surface, table.concat(points), EDGES, 2, "accent")
  end,

  -- a drag across turns the cube
  event = function(state, event)
    if event.type == "pointerDown" and event.button == 1 then
      state.dragging = event.x
    elseif event.type == "pointerUp" then
      state.dragging = nil
    elseif event.type == "pointerMove" and state.dragging then
      state.turn = state.turn + (event.x - state.dragging) * 0.01
      state.dragging = event.x
      state.panel:redraw()
    end
  end,

  -- what the test checks: the turn, where the last corner is in the view, and results that cglm must give
  saveState = function(state)
    local x, y = project(matrixAt(state.turn), CORNERS[8])
    local axis = cglm.vec3Normalize(cglm.vec3(1, 2, 3))
    local point = cglm.vec3(4, -1, 2)

    -- the largest difference between the floats of two buffers of as many floats
    local function difference(a, b)
      local largest = 0

      for i = 1, #a, 4 do
        largest = math.max(largest, math.abs(string.unpack("<f", a, i) - string.unpack("<f", b, i)))
      end

      return largest
    end

    local matrix = matrixAt(state.turn)
    local half = cglm.quatSlerp(cglm.quatv(0, UP), cglm.quatv(1, UP), 0.5)

    return {
      turn = state.turn,
      drawn = state.drawn,
      corner = { x = x, y = y },
      checks = {
        -- a matrix times its inverse changes nothing
        inverse = difference(cglm.mat4Mul(matrix, cglm.mat4Inv(matrix)), cglm.mat4Identity()),
        -- a quaternion turns as the matrix of the same axis and angle does
        quaternion = difference(cglm.quatMat4(cglm.quatv(0.7, axis)), cglm.rotateMake(0.7, axis)),
        rotatev = difference(cglm.quatRotatev(cglm.quatv(0.7, axis), point), cglm.mat4Mulv3(cglm.rotateMake(0.7, axis), point, 0)),
        -- halfway between no turn and a turn of 1 is a turn of 0.5
        slerp = difference(half, cglm.quatv(0.5, UP)),
        -- the camera sees the cube's centre straight ahead, at its distance
        camera = difference(cglm.mat4Mulv3(CAMERA, cglm.vec3(0, 0, 0), 1), cglm.vec3(0, 0, -math.sqrt(29))),
        -- a translation moves a point, and translate moves before what its matrix does
        translation = difference(cglm.mat4Mulv3(cglm.translateMake(cglm.vec3(1, 2, 3)), cglm.vec3(1, 1, 1), 1), cglm.vec3(2, 3, 4)),
        translate = difference(cglm.translate(cglm.scaleMake(cglm.vec3(2, 2, 2)), cglm.vec3(1, 2, 3)),
          cglm.mat4Mul(cglm.scaleMake(cglm.vec3(2, 2, 2)), cglm.translateMake(cglm.vec3(1, 2, 3)))),
        cross = difference(cglm.vec3Cross(cglm.vec3(1, 0, 0), cglm.vec3(0, 1, 0)), cglm.vec3(0, 0, 1)),
        -- Perlin noise is 0 at whole points
        noise = math.abs(cglm.perlinVec3(cglm.vec3(1, 2, 3))),
        length = cglm.vec3Norm(cglm.vec3(3, 4, 0)),
        singular = #cglm.mat4Inv(cglm.scaleMake(cglm.vec3(1, 0, 1))),
      },
    }
  end,
})
