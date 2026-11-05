-- Run it with: OpenECS --preset examples/s16_sqlite/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "sqlite",
  version = "0.1.0",
  app = { id = "openecs.example.sqlite", name = "SQLite" },
  hint = "The panel keeps a table of fruits in a database; Return adds one",
  depends = { records = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "records.panel" } } } } },
  },
}
