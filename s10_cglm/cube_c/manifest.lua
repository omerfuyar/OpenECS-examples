---@type ecs.Manifest
return {
  name = "cube_c",
  version = "0.1.0",
  api = 2,
  description = "The cube of the cube plugin, in C, with the cglm plugin's functions through its header",
  depends = { cglm = "0.1", draw = "0.1" },
  type = "native",
}
