-- Run it with: OpenECS --fresh --preset examples/s12_compress/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "compress",
  version = "0.1.0",
  app = { id = "openecs.example.compress", name = "Archive" },
  hint = "The plugin packs its own files in each format, and writes them into a zip archive beside them",
  depends = { archive = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "archive.panel" } } } } },
  },
}
