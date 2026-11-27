-- A native plugin that draws the same picture as shapes, in C. The build compiles every C file of the folder into the plugin's library.
---@type ecs.Manifest
return {
  name = "shapes_c",
  version = "0.1.0",
  api = 4,
  description = "A panel that draws gpu's shapes in C: rounded rectangles, circles, outlines, clipping and styled text",
  type = "native",
  depends = { draw = "0.1", gpu = "0.1" },
}
