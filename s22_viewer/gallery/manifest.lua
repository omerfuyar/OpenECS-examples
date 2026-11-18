---@type ecs.Manifest
return {
  name = "gallery",
  version = "0.1.0",
  api = 3,
  description = "Shows its own files in the viewer, one after another",
  depends = { viewer = "0.1" },
  type = "lua",
}
