-- Run it with: OpenECS --fresh --preset examples/s26_history/preset_both.lua
-- the tally in Lua and in C, each with its own history, beside the History panel, which shows the focused one's
---@type ecs.Preset
return {
  format = 3,
  name = "history_both",
  version = "0.1.0",
  app = { id = "openecs.example.history_both", name = "Two histories" },
  hint = "Ctrl+Z undoes the focused tally's changes only; the History panel shows the focused tally's history",
  depends = { tally = "0.1", tally_c = "0.1", history = "0.1" },
  pluginsDir = ".",
  workspaces = {
    {
      name = "Main",
      windows = {
        {
          split = "horizontal",
          { share = 2, panels = { { type = "tally.panel" } } },
          { share = 2, panels = { { type = "tally_c.panel" } } },
          { share = 1, panels = { { type = "history.list" } } },
        },
      },
    },
  },
}
