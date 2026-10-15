-- Run it with: OpenECS --preset examples/3_ui/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "ui",
  version = "0.1.0",
  app = { id = "openecs.example.ui", name = "Controls" },
  hint = "Click the controls, or press Tab to move between them; the About and Table tabs show a tree and a table",
  depends = { button = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "button.panel" } } } } },
  },
}
