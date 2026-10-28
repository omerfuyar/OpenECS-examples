-- Run it with: OpenECS --preset examples/c10_text_input/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "textinput",
  version = "0.1.0",
  app = { id = "openecs.example.textinput", name = "Text input" },
  hint = "Type in the field; Backspace deletes, and input methods, such as for accented letters, work too",
  depends = { field = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "field.panel" } } } } },
  },
}
