-- A canvas beside a panel that closes itself while it draws, for test-closer.lua.
---@type ecs.Preset
return {
  format = 1,
  name = "closer",
  version = "0.1.0",
  app = { id = "openecs.sketch.closer", name = "Closer" },
  depends = { sketch_lua = "0.1", closer = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main",
      windows = {
        { split = "horizontal",
          { panels = { { type = "sketch_lua.canvas" } } },
          { panels = { { type = "closer.panel" } } },
        },
      },
    },
  },
}
