-- Run it with: OpenECS --fresh --preset examples/16_model/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "model",
  version = "0.1.0",
  app = { id = "openecs.example.model", name = "Model" },
  hint = "A glTF cube turns, an animated badge spins, and a skinned arm bends; there is nothing to press",
  depends = { model = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "model.panel" } } } } },
  },
}
