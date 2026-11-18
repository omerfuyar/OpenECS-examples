---@type ecs.Manifest
return {
  name = "busy",
  version = "0.1.0",
  api = 2,
  description = "A panel that draws every frame, for the profiler to measure",
  depends = { draw = "0.1" },
  type = "lua",
}
