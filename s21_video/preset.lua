-- Run it with: OpenECS --preset examples/s21_video/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "video",
  version = "0.1.0",
  app = { id = "openecs.example.video", name = "Video" },
  hint = "Space plays and pauses the video; Left and Right go back and forward half a second",
  depends = { player = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "player.panel" } } } } },
  },
}
