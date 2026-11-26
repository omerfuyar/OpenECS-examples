-- Run it with: OpenECS --preset examples/c9_drag_drop/preset_c.lua
-- The palette of preset.lua beside the sample written in C.
---@type ecs.Preset
return {
  format = 1,
  name = "dragdrop-c",
  version = "0.1.0",
  app = { id = "openecs.example.dragdrop.c", name = "Drag and drop in C" },
  hint = "Drag a colour from the palette onto the sample in C",
  depends = { swatches = "0.1", swatches_c = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main",
      windows = {
        { split = "horizontal",
          { panels = { { type = "swatches.palette" } } },
          { panels = { { type = "swatches_c.sample" } } },
        },
      },
    },
  },
}
