-- Run it with: OpenECS --preset examples/3_ui/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "ui",
  version = "0.1.0",
  app = { id = "openecs.example.ui", name = "Controls" },
  hint = "Click the controls, or press Tab to move between them; the About and Table tabs show a tree and a table, and Alt+W, then 2 the same controls in C",
  depends = { button = "0.1", button_c = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "button.panel" } } } } },
    { name = "C",    windows = { { panels = { { type = "button_c.panel" } } } } },
  },
}
