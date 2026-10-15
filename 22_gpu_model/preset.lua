-- Run it with: OpenECS --fresh --preset examples/22_gpu_model/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "gpu_model",
  version = "0.1.0",
  app = { id = "openecs.example.gpu_model", name = "GPU model" },
  hint = "A glTF model drawn filled and lit on the GPU; drag to turn it, and turn the wheel to come nearer",
  depends = { shaded = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "shaded.panel" } } } } },
  },
}
