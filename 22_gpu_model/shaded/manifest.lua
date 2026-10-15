---@type ecs.Manifest
return {
  name = "shaded",
  version = "0.1.0",
  api = 1,
  description = "A glTF model drawn on the GPU with shaders of its own: gltf reads its vertices, normals and triangles, and gpu draws them with a pipeline",
  depends = { gltf = "0.1", gpu = "0.1" },
  type = "lua",
}
