-- Run it with: OpenECS --fresh --preset examples/s26_history/preset_default.lua
-- the tallies in Lua and in C, each with its own history, a note without one, and the History panel; tally_c makes its history the default
---@type ecs.Preset
return {
  format = 3,
  name = "history_default",
  version = "0.1.0",
  app = { id = "openecs.example.history_default", name = "A default history" },
  hint = "Ctrl+Z in the note undoes the tool's default history, the C tally's; in a tally, it undoes that tally's own",
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
          { share = 1, panels = { { type = "tally.note" } } },
          { share = 2, panels = { { type = "history.list" } } },
        },
      },
    },
  },
}
