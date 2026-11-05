---@type ecs.Manifest
return {
  name = "runner",
  version = "0.1.0",
  api = 2,
  description = "Runs programs with the process plugin, and shows what they wrote",
  depends = { process = "0.1", draw = "0.1" },
  type = "lua",
}
