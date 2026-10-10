-- Run it with: OpenECS --fresh --preset examples/13_terminal/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "terminal",
  version = "0.1.0",
  app = { id = "openecs.example.terminal", name = "Terminal" },
  depends = { terminal = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "terminal.panel" } } } } },
  },
}
