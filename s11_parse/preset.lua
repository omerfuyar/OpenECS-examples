-- Run it with: OpenECS --fresh --preset examples/s11_parse/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "parse",
  version = "0.1.0",
  app = { id = "openecs.example.parse", name = "Formats" },
  hint = "Each tab writes a table in one format, and reads the text back",
  depends = { formats = "0.1" },
  pluginsDir = ".",
  workspaces = {
    {
      name = "Main",
      windows = {
        {
          panels = {
            { type = "formats.panel", state = { format = "Json" } },
            { type = "formats.panel", state = { format = "Toml" } },
            { type = "formats.panel", state = { format = "Ini" } },
            { type = "formats.panel", state = { format = "Env" } },
            { type = "formats.panel", state = { format = "Csv" } },
          },
        },
      },
    },
  },
}
