-- Run it with: OpenECS --fresh --preset examples/s5_files/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "files",
  version = "0.1.0",
  app = { id = "openecs.example.files", name = "Files" },
  hint = "Click a folder to open it and a file to see its start; add or remove a file in the folder, and the list follows",
  depends = { files = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "files.panel" } } } } },
  },
}
