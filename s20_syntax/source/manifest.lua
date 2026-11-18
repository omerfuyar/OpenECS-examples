---@type ecs.Manifest
return {
  name = "source",
  version = "0.1.0",
  api = 3,
  description = "Shows source files with their syntax highlighted by the syntax plugin",
  depends = { syntax = "0.1", ui = "0.1" },
  type = "lua",
}
