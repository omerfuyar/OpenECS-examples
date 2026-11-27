---@type ecs.Manifest
return {
  name = "shapes",
  version = "0.1.0",
  api = 4,
  description = "A panel that draws gpu's shapes in Lua, as draw has them: rounded rectangles, circles, outlines, clipping and styled text",
  depends = { draw = "0.1", gpu = "0.1" },
  type = "lua",
}
