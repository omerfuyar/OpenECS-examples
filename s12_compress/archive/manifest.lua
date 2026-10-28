---@type ecs.Manifest
return {
  name = "archive",
  version = "0.1.0",
  api = 2,
  description = "Packs its own files with gzip, zlib, deflate and zstd, and writes and reads a zip archive of them, with the compress and ui plugins",
  depends = { compress = "0.1", ui = "0.1" },
  type = "lua",
}
