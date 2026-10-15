-- A glTF model drawn filled and lit on the GPU. The gltf standard plugin reads its vertices, normals and triangles; each frame, Lua turns them,
-- lights each vertex, and sorts the triangles from back to front, and the gpu standard plugin draws them in one mesh, with colours that blend.
-- 16_model draws models as lines on the CPU, with draw; this panel's surface is a GPU texture instead.
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
local points, normals, triangles = {}, {}, {}
local positions = model:attribute(1, 1, "POSITION")

-- the ring leans on its side, so it tumbles as it turns; a turn around its own axis would look still
local LEAN = math.rad(60)
local cz, sz = math.cos(LEAN), math.sin(LEAN)

local function lean(x, y, z)
  return x * cz - y * sz, x * sz + y * cz, z
end

for i = 0, VERTICES - 1 do
  points[i + 1] = { lean(string.unpack("<fff", positions, i * 12 + 1)) }
end

-- each call of attribute or indices replaces the buffer of the last one, so each is read before the next
local normalBytes = model:attribute(1, 1, "NORMAL")

for i = 0, VERTICES - 1 do
  normals[i + 1] = { lean(string.unpack("<fff", normalBytes, i * 12 + 1)) }
end

local indices = model:indices(1, 1)

for i = 0, TRIANGLES - 1 do
  local a, b, c = string.unpack("<I4I4I4", indices, i * 12 + 1)
  triangles[i + 1] = { a, b, c }
end

-- the material's colour, from 0 to 1, which the light makes brighter or darker
local BASE = info.materials[primitive.material].color

-- the light comes from the top left and from in front, towards the model; a little of it reaches every side
local LIGHT = { -0.45, 0.65, -0.6 }
local length = math.sqrt(LIGHT[1] ^ 2 + LIGHT[2] ^ 2 + LIGHT[3] ^ 2)
LIGHT = { LIGHT[1] / length, LIGHT[2] / length, LIGHT[3] / length }
local AMBIENT = 0.22

-- a vertex's colour, ARGB: the material's colour lit by how much the normal faces the light, with a highlight where it faces it most
local function shade(nx, ny, nz)
  local facing = math.max(0, nx * LIGHT[1] + ny * LIGHT[2] + nz * LIGHT[3])
  local light = AMBIENT + (1 - AMBIENT) * facing
  local highlight = facing ^ 24 * 0.5
  local function channel(base)
    return math.floor(math.min(1, base * light + highlight) * 255 + 0.5)
  end
  return 0xFF000000 | (channel(BASE[1]) << 16) | (channel(BASE[2]) << 8) | channel(BASE[3])
end

ecs.panel.registerType({
  name = "panel",
  title = "Shaded model",
  surface = "gpu",
  continuous = true,

  create = function()
    return { turn = 0.6, tilt = 0.3, distance = 4, drawn = 0, shown = 0, dragging = nil }
  end,

  draw = function(view, surface, seconds)
    view.drawn = view.drawn + 1

    if not view.dragging then
      view.turn = view.turn + seconds * 0.7
    end

    local frame = gpu.frame(surface)

    if not frame then
      return
    end

    -- each vertex turns around the vertical axis, then leans by the tilt, and is seen in perspective from the front
    local width, height = surface.width / surface.scale, surface.height / surface.scale
    local scale = math.min(width, height) * 0.42
    local ct, st, cl, sl = math.cos(view.turn), math.sin(view.turn), math.cos(view.tilt), math.sin(view.tilt)
    local projected, colors, depths, facing = {}, {}, {}, {}

    for i = 1, VERTICES do
      local p, n = points[i], normals[i]
      local x, z = p[1] * ct - p[3] * st, p[1] * st + p[3] * ct
      local y
      y, z = p[2] * cl - z * sl, p[2] * sl + z * cl
      local nx, nz = n[1] * ct - n[3] * st, n[1] * st + n[3] * ct
      local ny
      ny, nz = n[2] * cl - nz * sl, n[2] * sl + nz * cl

      local perspective = view.distance / (z + view.distance + 1)
      projected[i] = string.pack("=ff", width / 2 + x * scale * perspective, height / 2 - y * scale * perspective)
      colors[i] = string.pack("=I4", shade(nx, ny, nz))
      depths[i], facing[i] = z, nz
    end

    -- triangles that face away are left out, and the rest are drawn from the farthest to the nearest, so the near ones cover the far ones
    local shown = {}

    for _, t in ipairs(triangles) do
      local a, b, c = t[1] + 1, t[2] + 1, t[3] + 1

      if facing[a] + facing[b] + facing[c] < 0.3 then
        shown[#shown + 1] = { depth = depths[a] + depths[b] + depths[c], t = t }
      end
    end

    table.sort(shown, function(left, right) return left.depth > right.depth end)
    local order = {}

    for i, triangle in ipairs(shown) do
      order[i] = string.pack("=I4I4I4", triangle.t[1], triangle.t[2], triangle.t[3])
    end

    view.shown = #shown
    frame:clear(BACKGROUND)
    frame:mesh(table.concat(projected), table.concat(colors), table.concat(order))
    frame:submit()
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

  -- what the test checks: the model's size, how many frames it drew, and how many triangles the last frame showed
  saveState = function(view)
    return { vertices = VERTICES, triangles = TRIANGLES, drawn = view.drawn, shown = view.shown, turn = view.turn, distance = view.distance }
  end,
})
