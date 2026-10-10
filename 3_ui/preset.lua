-- Run it with: OpenECS --preset examples/3_ui/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "ui",
  version = "0.1.0",
  app = { id = "openecs.example.ui", name = "Button" },
  depends = { button = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "button.panel" } } } } },
  },
}
