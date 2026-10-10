---@type ecs.Manifest
return {
  name = "media",
  version = "0.1.0",
  api = 1,
  description = "A picture that plays a sound when it is clicked, with the image and audio plugins",
  depends = { image = "0.1", audio = "0.1" },
  lua = "init.lua",
}
