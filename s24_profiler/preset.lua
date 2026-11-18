-- Run it with: OpenECS --fresh --preset examples/s24_profiler/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "profiler",
  version = "0.1.0",
  app = { id = "openecs.example.profiler", name = "Profiler" },
  hint = "Turn Measure on: the profiler shows each plugin's own time, each panel's draw and each step of the frames; Alt+W, then F opens it in any tool",
  depends = { busy = "0.1", profiler = "0.1" },
  pluginsDir = ".",
  workspaces = {
    {
      name = "Main",
      windows = {
        {
          split = "horizontal",
          { share = 1, panels = { { type = "busy.panel" } } },
          { share = 2, panels = { { type = "profiler.view" } } },
        },
      },
    },
  },
}
