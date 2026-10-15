-- Run it with: OpenECS --preset examples/19_first_party/preset.lua
-- A tool made of one plugin of its own and the first-party plugins that every tool has: the settings window, the panel list and the launcher.
---@type ecs.Preset
return {
  format = 1,
  name = "first party",
  version = "0.1.0",
  app = { id = "openecs.example.firstParty", name = "First party" },
  hint = "Alt+W, then , opens the settings, N lists the panels to open, and Shift+O opens the launcher",
  -- the core's settings file loads settings, panels and launcher for every tool; a preset names them too when it needs them, as a test loads only the preset's plugins
  depends = { shapes = "0.1", settings = "0.1", panels = "0.1", launcher = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "shapes.square" } } } } },
  },
}
