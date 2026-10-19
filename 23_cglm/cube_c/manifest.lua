---@type ecs.Manifest
return {
  name = "cube_c",
  version = "0.1.0",
  api = 1,
  description = "The cube of the cube plugin, in C with cglm's own functions, through the cglm plugin's header",
  depends = { cglm = "0.1", draw = "0.1" },
  type = "native",
}
