-- Run it with: OpenECS --preset examples/s20_syntax/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "syntax",
  version = "0.1.0",
  app = { id = "openecs.example.syntax", name = "Syntax" },
  hint = "The viewer shows a C, a Lua and a JSON file with their syntax highlighted; the selector chooses one",
  depends = { viewer = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "viewer.panel" } } } } },
  },
}
