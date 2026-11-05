---@type ecs.Manifest
return {
  name = "badges",
  version = "0.1.0",
  api = 2,
  description = "A badge that counts the shapes' panels; it needs shapes, so disabling shapes disables it too",
  depends = { shapes = "0.1", draw = "0.1" },
  type = "lua",
}
