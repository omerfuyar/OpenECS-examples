-- the tool of preset.lua, reloading its plugin when the plugin's files change: hello_c then loads from a copy of its library, so a new build
-- can replace the library while the tool runs
---@type ecs.Preset
return {
  format = 1,
  name = "native-reload",
  version = "0.1.0",
  app = { id = "openecs.example.native-reload", name = "Hello in C, reloading" },
  depends = { hello_c = "0.1" },
  pluginsDir = ".",
  settings = { ["ecs.reloadPlugins"] = true },
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "hello_c.greeting" } } } } },
  },
}
