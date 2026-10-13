-- Run it with: OpenECS --fresh --preset examples/16_model/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "model",
  version = "0.1.0",
  app = { id = "openecs.example.model", name = "Model" },
  depends = { model = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "model.panel" } } } } },
  },
}
