-- Run it with: OpenECS --preset examples/c11_popups/preset.lua
-- Right-click the panel to choose its colour from a menu.
---@type ecs.Preset
return {
  format = 1,
  name = "popups",
  version = "0.1.0",
  app = { id = "openecs.example.popups", name = "Popups" },
  hint = "Right-click the panel to choose its colour from a menu",
  depends = { picker = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "picker.panel" } } } } },
  },
}
