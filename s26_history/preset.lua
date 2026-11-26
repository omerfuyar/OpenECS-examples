-- Run it with: OpenECS --fresh --preset examples/s26_history/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "history",
  version = "0.1.0",
  app = { id = "openecs.example.history", name = "History" },
  hint = "Ctrl+Z and Ctrl+Y undo and redo the tally's changes; the History panel lists them, and a click on one goes back to it",
  depends = { tally = "0.1", history = "0.1" },
  pluginsDir = ".",
  workspaces = {
    {
      name = "Main",
      windows = {
        {
          split = "horizontal",
          { share = 2, panels = { { type = "tally.panel" } } },
          { share = 1, panels = { { type = "history.list" } } },
        },
      },
    },
  },
}
