-- Run it with: OpenECS --fresh --preset examples/20_workers/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "workers",
  version = "0.1.0",
  app = { id = "openecs.example.workers", name = "Workers" },
  hint = "Choose how far to count and press Start: four workers count the primes on their own threads, and the panel stays free",
  depends = { primes = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "primes.panel" } } } } },
  },
}
