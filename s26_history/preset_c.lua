-- Run it with: OpenECS --fresh --preset examples/s26_history/preset_c.lua
---@type ecs.Preset
return {
  format = 3,
  name = "history_c",
  version = "0.1.0",
  app = { id = "openecs.example.history_c", name = "History in C" },
  hint = "Ctrl+Z and Ctrl+Y undo and redo the tally's changes; the History panel lists them, and a click on one goes back to it",
  depends = { tally_c = "0.1", history = "0.1" },
  pluginsDir = ".",
  workspaces = {
    {
      name = "Main",
      windows = {
        {
          split = "horizontal",
          { share = 2, panels = { { type = "tally_c.panel" } } },
          { share = 1, panels = { { type = "history.list" } } },
        },
      },
    },
  },
}
