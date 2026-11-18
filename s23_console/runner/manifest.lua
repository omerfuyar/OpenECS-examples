---@type ecs.Manifest
return {
  name = "runner",
  version = "0.1.0",
  api = 3,
  description = "Runs a pretend program, whose output goes to the console",
  depends = { console = "0.1", ui = "0.1" },
  type = "lua",
}
