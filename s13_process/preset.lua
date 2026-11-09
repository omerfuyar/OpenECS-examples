-- Run it with: OpenECS --preset examples/s13_process/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "process",
  version = "0.1.0",
  app = { id = "openecs.example.process", name = "Process" },
  hint = "The panel shows what programs that the runner plugin started wrote",
  depends = { runner = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "runner.panel" } } } } },
  },
}
