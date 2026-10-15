-- A panel that draws with the GPU, in Lua: the gpu standard plugin draws shapes, lines and textures into a GPU surface, as draw does into pixels.
-- It draws the same picture as lights_c, which uses SDL's GPU API in C: four tiles on a background, and a light that goes along the bottom, pulsing.

local ecs = require("ecs")
local gpu = require("gpu")

local BACKGROUND = "#1B2A4A"
local TILES = { "#BF616A", "#A3BE8C", "#EBCB8B", "#5E81AC" }

-- the light is a texture, made once from pixels: a soft yellow dot, ARGB with premultiplied alpha, as draw's images have
local function dot(size)
  local pixels = {}

  for y = 0, size - 1 do
    for x = 0, size - 1 do
      local distance = math.sqrt((x + 0.5 - size / 2) ^ 2 + (y + 0.5 - size / 2) ^ 2) / (size / 2)
      local alpha = math.max(0, 1 - distance)
      local function channel(value) return math.floor(value * alpha + 0.5) end
      pixels[#pixels + 1] = string.pack("<I4", (channel(255) << 24) | (channel(0xEB) << 16) | (channel(0xCB) << 8) | channel(0x8B))
    end
  end

  -- nil without a GPU renderer; the panel then draws nothing
  return gpu.texture(size, size, table.concat(pixels))
end

local light = dot(32)

ecs.panel.registerType({
  name = "panel",
  title = "Lights in Lua",
  surface = "gpu",   -- the panel draws into a GPU texture instead of pixels
  continuous = true, -- the light moves, so the panel draws every frame

  create = function()
    return { seconds = 0 }
  end,

  draw = function(lights, surface, seconds)
    lights.seconds = lights.seconds + seconds

    -- gpu draws into the surface as draw does into pixels; what it draws reaches the GPU when draw returns
    local width, height = surface.width / surface.scale, surface.height / surface.scale
    gpu.clear(surface, BACKGROUND)

    -- the four tiles fill a square in the middle, half as tall as the panel
    local side = math.floor(math.min(width, height) / 2)
    local left, top, half = math.floor((width - side) / 2), math.floor((height - side) / 2), side / 2
    gpu.fill(surface, left, top, half, half, TILES[1])
    gpu.fill(surface, left + half, top, half, half, TILES[2])
    gpu.fill(surface, left, top + half, half, half, TILES[3])
    gpu.fill(surface, left + half, top + half, half, half, TILES[4])

    -- a line under the tiles, and the light, which goes along the bottom and back every four seconds; the colour multiplies its pixels, so its alpha pulses
    gpu.line(surface, left, top + side + 8, left + side, top + side + 8, 2, "accent")
    local size = math.floor(side / 8) + 1
    local phase = lights.seconds / 4 % 1
    local across = phase < 0.5 and phase * 2 or 2 - phase * 2

    if light then
      local alpha = math.floor(191 + 64 * math.sin(lights.seconds * 4))
      gpu.imageTransformed(surface, light, across * (width - size * 2), height - size * 3, size * 2, size * 2, 0, ("#FFFFFF%02X"):format(alpha))
    end

  end,
})
