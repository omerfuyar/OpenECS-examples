---@type ecs.Manifest
return {
  name = "model",
  version = "0.1.0",
  api = 1,
  description = "A glTF model that turns, read with the gltf plugin and drawn as lines with draw",
  depends = { gltf = "0.1", draw = "0.1" },
  type = "lua",
}
