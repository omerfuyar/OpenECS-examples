-- Run it with: OpenECS --fresh --preset examples/s2_media/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "media",
  version = "0.1.0",
  app = { id = "openecs.example.media", name = "Media" },
  hint = "Click the picture for a sound; R turns it, F fades it, S saves it, B and E play tones, T a tune, M muffles the tune, V adds a reverb",
  depends = { media = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "media.panel" } } } } },
  },
}
