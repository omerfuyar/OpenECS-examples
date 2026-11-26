---@type ecs.Manifest
return {
  name = "watcher_c",
  version = "0.1.0",
  api = 4,
  description = "The watcher plugin in C: it watches a folder and the folders inside it with fs",
  depends = { fs = "0.1" },
  type = "native",
}
