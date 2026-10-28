-- Run it with: OpenECS --preset examples/c7_events/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "events",
  version = "0.1.0",
  app = { id = "openecs.example.events", name = "Events" },
  hint = "The panels count the ticker's ticks; Alt+W, then ., opens another panel, and every panel hears that it opened",
  depends = { ticker = "0.1", listener = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "listener.panel" } } } } },
  },
}
