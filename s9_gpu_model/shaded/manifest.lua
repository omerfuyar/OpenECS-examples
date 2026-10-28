---@type ecs.Manifest
return {
  name = "shaded",
  version = "0.1.0",
  api = 2,
  description = "A glTF model drawn on the GPU with shaders of its own: gltf reads its vertices, normals and triangles, and gpu draws them with a pipeline and cglm's matrices, and a label with the glyphs of a text",
  depends = { draw = "0.1", gltf = "0.1", gpu = "0.1", cglm = "0.1" },
  type = "lua",
}
