-- The controls of preset.lua with the setting ui.gpu off: ui.panelType and Ui_PanelType put both panels on pixels, and draw draws them
-- Run it with: OpenECS --preset examples/c3_ui/preset_pixels.lua
---@type ecs.Preset
return {
  format = 1,
  name = "ui-pixels",
  version = "0.1.0",
  app = { id = "openecs.example.ui", name = "Controls" },
  hint = "The same controls as preset.lua, drawn into pixels, as the setting ui.gpu is off; Alt+W, then 2 shows them in C",
  depends = { button = "0.1", button_c = "0.1" },
  pluginsDir = ".",
  settings = { ["ui.gpu"] = false },
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "button.panel" } } } } },
    { name = "C",    windows = { { panels = { { type = "button_c.panel" } } } } },
  },
}
