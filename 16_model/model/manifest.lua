---@type ecs.Manifest
return {
  name = "model",
  version = "0.1.0",
  api = 1,
  description = "A glTF model that turns, drawn as lines, with the gltf plugin",
  depends = { gltf = "0.1" },
  lua = "init.lua",
}
