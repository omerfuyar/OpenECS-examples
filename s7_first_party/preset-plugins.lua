-- The preset of test-plugins.lua: the shapes and badges plugins, and the plugin list, which enables and disables them.
---@type ecs.Preset
return {
  format = 3,
  name = "plugins",
  version = "0.1.0",
  app = { id = "openecs.example.plugins", name = "Plugins" },
  hint = "Alt+W, then ; lists the plugins; Return enables or disables the chosen one",
  depends = { shapes = "0.1", badges = "0.1", plugins = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "shapes.square" }, { type = "badges.badge" } } } } },
  },
}
