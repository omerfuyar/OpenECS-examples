-- Run it with: OpenECS --fresh --preset examples/17_files/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "files",
  version = "0.1.0",
  app = { id = "openecs.example.files", name = "Files" },
  depends = { files = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "files.panel" } } } } },
  },
}
