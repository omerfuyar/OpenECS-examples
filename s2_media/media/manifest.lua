---@type ecs.Manifest
return {
  name = "media",
  version = "0.1.0",
  api = 1,
  description = "A picture that plays a sound when it is clicked, turns and fades, and a streamed tune: image and audio read the files, draw and mixer use them",
  depends = { image = "0.1", draw = "0.1", audio = "0.1", mixer = "0.1" },
  type = "lua",
}
