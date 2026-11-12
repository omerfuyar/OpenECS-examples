-- Run it with: OpenECS --preset examples/c8_state/preset.lua
-- Quit and run it again: the marks come back, because the tool's last session keeps them.
---@type ecs.Preset
return {
  format = 1,
  name = "state",
  version = "0.1.0",
  app = { id = "openecs.example.state", name = "State" },
  hint = "Click to place dots, then quit and start again: the tool's last session brings them back",
  depends = { marks = "0.1" },
  pluginsDir = ".",
  -- while it runs, a saved change to marks/init.lua reloads the plugin: its panels keep their dots, and the plugin its count, through the reload
  settings = { ["ecs.reloadPlugins"] = true },
  workspaces = {
    { name = "Main",
      windows = {
        { split = "horizontal",
          { panels = { { type = "marks.panel" } } },
          -- a preset may give a panel a saved state to start from
          { panels = { { type = "marks.panel", stateVersion = 1, state = { dots = { 40, 40, 80, 80 } } } } },
        },
      },
    },
  },
}
