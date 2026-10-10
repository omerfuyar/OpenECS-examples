-- Run it with: OpenECS --fresh --preset examples/14_media/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "media",
  version = "0.1.0",
  app = { id = "openecs.example.media", name = "Media" },
  depends = { media = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "media.panel" } } } } },
  },
}
