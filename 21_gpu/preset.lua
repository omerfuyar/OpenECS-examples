-- Run it with: OpenECS --fresh --preset examples/21_gpu/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "gpu",
  version = "0.1.0",
  app = { id = "openecs.example.gpu", name = "GPU" },
  hint = "Both panels draw with the GPU; pop one out with Alt+W, then P, and it keeps drawing in its own window",
  depends = { lights = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "lights.panel" }, { type = "lights.panel" } } } } },
  },
}
