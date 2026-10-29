-- Run it with: OpenECS --preset examples/c14_structs/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "structs",
  version = "0.1.0",
  app = { id = "openecs.example.structs", name = "Structs" },
  hint = "Click to add points to the path: the title shows its length. Alt+W, then ., opens another panel",
  depends = { path = "0.1" }, -- path depends on geometry, so geometry loads too
  pluginsDir = ".",
  workspaces = {
    { name = "Main",
      windows = {
        { panels = { { type = "path.panel" } } },
      },
    },
  },
}
