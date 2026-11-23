-- The workers' panel with the switch plugin, whose functions disable and enable the primes plugin while it counts.
---@type ecs.Preset
return {
  format = 1,
  name = "switch",
  version = "0.1.0",
  app = { id = "openecs.example.switch", name = "Switch" },
  depends = { primes = "0.1", switch = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "primes.panel" } } } } },
  },
}
