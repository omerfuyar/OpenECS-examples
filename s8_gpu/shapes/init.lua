-- A panel that draws, with the GPU, the shapes that draw has for pixels: a rounded rectangle and its edge, a circle and a ring, an outline, two
-- clips, one inside the other, a pipeline of its own inside a clip, and text in a font and in its bold style. shapes_c draws the same picture in C, but for the pipeline. gpu's shapes take draw's arguments,
-- so a plugin that draws with draw draws the same with gpu.

local ecs = require("ecs")
local ffi = require("ffi")
local draw = require("draw")
local gpu = require("gpu")

local regular = draw.font("ui")
local bold = draw.styledFont("ui", "bold")

-- a pipeline of its own, which draws one triangle over the whole surface in teal; inside a clip, only the clip shows it. nil without a GPU renderer
local cover = gpu.buffer("vertex", ffi.new("float[6]", -1, -1, 3, -1, -1, 3))
local teal = gpu.pipeline({
  vertex = gpu.shader({ stage = "vertex", glsl = "#version 450\nlayout(location = 0) in vec2 point;\nvoid main() { gl_Position = vec4(point, 0.0, 1.0); }\n" }),
  fragment = gpu.shader({ stage = "fragment", glsl = "#version 450\nlayout(location = 0) out vec4 color;\nvoid main() { color = vec4(0.0, 128.0 / 255.0, 128.0 / 255.0, 1.0); }\n" }),
  attributes = { "float2" },
  depth = false,
})

local function picture(surface, draws)
  gpu.clear(surface, "#1B2A4A")
  gpu.rounded(surface, 10, 10, 60, 40, 12, "#BF616A")
  gpu.roundedOutline(surface, 80, 10, 60, 40, 12, 4, "#A3BE8C")
  gpu.circle(surface, 40, 80, 20, 0, "#EBCB8B")
  gpu.circle(surface, 110, 80, 20, 4, "#5E81AC")
  gpu.outline(surface, 150, 10, 40, 40, 3, "#88C0D0")

  -- the inner clip keeps to the outer one: its clear fills only where both overlap
  gpu.clip(surface, 150, 60, 20, 40, function()
    gpu.fill(surface, 150, 60, 40, 40, "#B48EAD")
    gpu.clip(surface, 150, 60, 40, 10, function()
      gpu.clear(surface, "#D08770")
    end)
  end)

  -- pipelines keep to a clip too
  if teal and cover then
    gpu.clip(surface, 200, 10, 30, 40, function()
      gpu.draw(surface, teal, { vertices = cover })
    end)
  end

  gpu.text(surface, regular, "Wide", 10, 110, 16, "#ECEFF4")
  gpu.text(surface, bold, "Wide", 10, 130, 16, "#ECEFF4")

  -- a row of numbers that change at each draw: gpu keeps the last texts it laid out, so words that stay are laid out once, and
  -- drops the oldest, so numbers that change do not fill the memory
  for k = 0, 15 do
    gpu.text(surface, regular, tostring(draws * 16 + k), 10 + k * 40, 155, 12, "#81A1C1")
  end
end

ecs.panel.registerType({
  name = "panel",
  title = "Shapes in Lua",
  surface = "gpu",
  create = function(panel) return { panel = panel, draws = 0 } end,
  draw = function(self, surface)
    self.draws = self.draws + 1
    picture(surface, self.draws)
  end,
  -- the panel draws again when the pointer moves over it, so its numbers change
  event = function(self, event)
    if event.type == "pointerMove" then self.panel:redraw() end
  end,
  -- its count of draws, which the test reads; a new panel counts from 0
  saveState = function(self) return { draws = self.draws } end,
})
