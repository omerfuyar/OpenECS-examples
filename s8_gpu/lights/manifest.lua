---@type ecs.Manifest
return {
  name = "lights",
  version = "0.1.0",
  api = 2,
  description = "A panel that draws with the GPU in Lua, with the gpu standard plugin: rectangles, a line, a texture that pulses, and text",
  depends = { draw = "0.1", gpu = "0.1" },
  type = "lua",
}
