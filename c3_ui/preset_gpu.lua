-- The controls of preset.lua with the setting ui.gpu on: ui.panelType and Ui_PanelType put both panels on the GPU, and gpu draws them
-- Run it with: OpenECS --preset examples/c3_ui/preset_gpu.lua
---@type ecs.Preset
return {
  format = 1,
  name = "ui-gpu",
  version = "0.1.0",
  app = { id = "openecs.example.ui", name = "Controls" },
  hint = "The same controls as preset.lua, drawn on the GPU, as the setting ui.gpu says; Alt+W, then 2 shows them in C",
  depends = { button = "0.1", button_c = "0.1" },
  pluginsDir = ".",
  settings = { ["ui.gpu"] = true },
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "button.panel" } } } } },
    { name = "C",    windows = { { panels = { { type = "button_c.panel" } } } } },
  },
}
