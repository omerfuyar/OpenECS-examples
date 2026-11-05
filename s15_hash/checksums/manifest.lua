---@type ecs.Manifest
return {
  name = "checksums",
  version = "0.1.0",
  api = 2,
  description = "Shows hashes of a text and of a file with the hash plugin",
  depends = { hash = "0.1", draw = "0.1" },
  type = "lua",
}
