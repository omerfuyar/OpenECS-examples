---@type ecs.Manifest
return {
  name = "terminal",
  version = "0.1.0",
  api = 1,
  description = "A small terminal with a few commands, drawn with the textgrid plugin",
  depends = { textgrid = "0.1" },
  type = "lua",
}
