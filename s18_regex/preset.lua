-- Run it with: OpenECS --preset examples/s18_regex/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "regex",
  version = "0.1.0",
  app = { id = "openecs.example.regex", name = "Regex" },
  hint = "Type a pattern to filter the log's lines; Exact text matches what you type as it is",
  depends = { logfilter = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "logfilter.panel" } } } } },
  },
}
