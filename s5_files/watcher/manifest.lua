---@type ecs.Manifest
return {
  name = "watcher",
  version = "0.1.0",
  api = 4,
  description = "Watches a folder and the folders inside it with fs, and shows what changed",
  depends = { fs = "0.1", draw = "0.1" },
  type = "lua",
}
