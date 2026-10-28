---@type ecs.Manifest
return {
  name = "cube",
  version = "0.1.0",
  api = 2,
  description = "A cube's edges, turned and seen in perspective with cglm's matrices, and drawn as lines with draw",
  depends = { cglm = "0.1", draw = "0.1" },
  type = "lua",
}
