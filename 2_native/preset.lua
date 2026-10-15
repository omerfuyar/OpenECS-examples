-- Run it with: OpenECS --preset examples/2_native/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "native",
  version = "0.1.0",
  app = { id = "openecs.example.native", name = "Hello in C" },
  hint = "The panel of 1_hello, written in C. Drag its tab to the edge of the window to split it, and Alt+W shows the core's keys",
  depends = { hello_c = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "hello_c.greeting" } } } } },
  },
}
