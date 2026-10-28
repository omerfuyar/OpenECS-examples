---@type ecs.Manifest
return {
  name = "tally",
  version = "0.1.0",
  api = 2,
  description = "Panels that count clicks with the counter plugin",
  depends = { counter = "0.1", draw = "0.1" },
  type = "lua",
}
