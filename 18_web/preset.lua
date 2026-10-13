-- Run it with: OpenECS --fresh --preset examples/18_web/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "web",
  version = "0.1.0",
  app = { id = "openecs.example.web", name = "Web" },
  depends = { fetch = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "fetch.panel" } } } } },
  },
}
