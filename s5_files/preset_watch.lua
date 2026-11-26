-- Run it with: OpenECS --fresh --preset examples/s5_files/preset_watch.lua
---@type ecs.Preset
return {
  format = 3,
  name = "watcher",
  version = "0.1.0",
  app = { id = "openecs.example.watcher", name = "Watcher" },
  hint = "The panel shows the changes of the folder that watcher.start watches, and of the folders inside it",
  depends = { watcher = "0.1", watcher_c = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "watcher.panel" } } } } },
  },
}
