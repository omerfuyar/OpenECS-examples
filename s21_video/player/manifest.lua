---@type ecs.Manifest
return {
  name = "player",
  version = "0.1.0",
  api = 2,
  description = "Plays a video file with the video plugin",
  depends = { video = "0.1", draw = "0.1" },
  type = "lua",
}
