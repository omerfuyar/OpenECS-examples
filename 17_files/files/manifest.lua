---@type ecs.Manifest
return {
  name = "files",
  version = "0.1.0",
  api = 1,
  description = "Browses folders and shows the start of a file, with the fs and ui plugins and Lua's io library",
  depends = { fs = "0.1", ui = "0.1" },
  lua = "init.lua",
}
