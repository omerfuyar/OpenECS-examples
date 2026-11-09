---@type ecs.Manifest
return {
  name = "path",
  version = "0.1.0",
  api = 2,
  description = "Panels that draw a path of clicked points and measure it with geometry's vectors",
  depends = { geometry = "0.1", draw = "0.1" },
  type = "lua",
}
