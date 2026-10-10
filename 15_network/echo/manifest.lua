---@type ecs.Manifest
return {
  name = "echo",
  version = "0.1.0",
  api = 1,
  description = "A server and a client on this computer that send each other lines, with the net plugin",
  depends = { net = "0.1", draw = "0.1" },
  lua = "init.lua",
}
