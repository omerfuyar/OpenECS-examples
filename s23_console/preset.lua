-- Run it with: OpenECS --fresh --preset examples/s23_console/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "console",
  version = "0.1.0",
  app = { id = "openecs.example.console", name = "Console" },
  hint = "Run adds a program's output to the console; a click on the place that an entry names, or a double click on the entry, opens the file in the code editor",
  depends = { runner = "0.1", console = "0.1" },
  pluginsDir = ".",
  -- the command that opens a file at a line; here it only marks the file, so the test sees that a click ran it
  -- the console shows no line of the log at first, as the core's lines differ on each machine; the test chooses its warnings
  settings = { ["console.editor"] = "touch {file}.{line}", ["console.logLevel"] = "off" },
  workspaces = {
    {
      name = "Main",
      windows = {
        {
          split = "vertical",
          { size = 48, panels = { { type = "runner.panel" } } },
          { share = 1, panels = { { type = "console.log" } } },
        },
      },
    },
  },
}
