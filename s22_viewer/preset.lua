-- Run it with: OpenECS --fresh --preset examples/s22_viewer/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "viewer",
  version = "0.1.0",
  app = { id = "openecs.example.viewer", name = "Viewer" },
  hint = "The buttons in the title bar show an image, a sound, then this example's own code",
  depends = { gallery = "0.1", viewer = "0.1" },
  pluginsDir = ".",
  settings = {
    -- the tool's own buttons in the title bar, after the core's menus: a label may be a symbol, and a button with a setting shows on while it is true
    ["ecs.titleButtons"] = {
      { "gallery.previous", label = "\u{25C0}" },
      { "gallery.next", label = "\u{25B6}" },
      { "gallery.slideshow", label = "Slideshow", setting = "gallery.slideshow" },
    },
  },
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "viewer.file" } } } } },
  },
}
