-- Run it with: OpenECS --fresh --preset examples/s22_viewer/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "viewer",
  version = "0.1.0",
  app = { id = "openecs.example.viewer", name = "Viewer" },
  hint = "Next File, in the tool's menu, shows an image, a sound, then this example's own code",
  depends = { gallery = "0.1", viewer = "0.1" },
  pluginsDir = ".",
  -- the tool's menu, which a right click on the title bar opens, lists the gallery's function
  settings = { ["ecs.toolMenu"] = { "gallery.next" } },
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "viewer.file" } } } } },
  },
}
