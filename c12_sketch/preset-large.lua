-- two workspaces of the sketch example at ecs.scale 1.5: the title bar, its window buttons and the margins grow with the scale
---@type ecs.Preset
return {
  format = 1,
  name = "sketch-large",
  version = "0.1.0",
  app = { id = "openecs.sketch-large", name = "Sketch" },
  depends = { sketch_c = "0.1", sketch_lua = "0.1" },
  pluginsDir = ".",
  settings = { ["ecs.scale"] = 1.5 },
  workspaces = {
    { name = "C", windows = { { panels = { { type = "sketch_c.canvas" } } } } },
    { name = "Side by side",
      windows = {
        { split = "vertical",
          { panels = { { type = "sketch_c.canvas" } } },
          { panels = { { type = "sketch_lua.canvas" } } },
        },
      },
    },
  },
}
