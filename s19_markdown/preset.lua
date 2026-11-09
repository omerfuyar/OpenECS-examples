-- Run it with: OpenECS --preset examples/s19_markdown/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "markdown",
  version = "0.1.0",
  app = { id = "openecs.example.markdown", name = "Markdown" },
  hint = "The panel shows help.md, a Markdown file, with ui's elements; the wheel scrolls it",
  depends = { help = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "help.panel" } } } } },
  },
}
