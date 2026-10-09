---@type ecs.Manifest
return {
  name = "swatches",
  version = "0.1.0",
  api = 1,
  description = "A palette whose colours drag onto samples",
  depends = { draw = "0.1" },
  lua = "init.lua",
}
