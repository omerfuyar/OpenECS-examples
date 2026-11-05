-- Run it with: OpenECS --preset examples/s15_hash/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "hash",
  version = "0.1.0",
  app = { id = "openecs.example.hash", name = "Hash" },
  hint = "The panel shows the hashes of a text with every algorithm, and of a file read in parts",
  depends = { checksums = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "checksums.panel" } } } } },
  },
}
