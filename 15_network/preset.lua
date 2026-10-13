-- Run it with: OpenECS --fresh --preset examples/15_network/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "network",
  version = "0.1.0",
  app = { id = "openecs.example.network", name = "Network" },
  depends = { echo = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "echo.panel" } } } } },
  },
}
