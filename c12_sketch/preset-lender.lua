-- The C canvas with the lender plugin, which frees a brush that the canvas uses while Lua holds its handle.
---@type ecs.Preset
return {
  format = 1,
  name = "lender",
  version = "0.1.0",
  app = { id = "openecs.sketch.lender", name = "Lender" },
  depends = { sketch_c = "0.1", lender = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "sketch_c.canvas" } } } } },
  },
}
