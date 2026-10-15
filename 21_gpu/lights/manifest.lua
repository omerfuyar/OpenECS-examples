---@type ecs.Manifest
return {
  name = "lights",
  version = "0.1.0",
  api = 1,
  description = "A panel that draws with the GPU in Lua, with the gpu standard plugin: rectangles, a line, and a texture that pulses",
  depends = { gpu = "0.1" },
  type = "lua",
}
