-- Run it with: OpenECS --fresh --preset examples/s8_gpu/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "gpu",
  version = "0.1.0",
  app = { id = "openecs.example.gpu", name = "GPU" },
  hint = "The panels draw with the GPU, in Lua and in C; pop one out with Alt+W, then P, and it keeps drawing in its own window",
  depends = { lights = "0.1", lights_c = "0.1", shapes = "0.1", shapes_c = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main",
      windows = {
        { split = "horizontal",
          { panels = { { type = "lights.panel" }, { type = "lights_c.panel" } } },
          { split = "vertical",
            { panels = { { type = "shapes.panel" } } },
            { panels = { { type = "shapes_c.panel" } } },
          },
        },
      },
    },
  },
}
