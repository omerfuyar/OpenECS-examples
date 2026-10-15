-- Run it with: OpenECS --fresh --preset examples/18_web/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "web",
  version = "0.1.0",
  app = { id = "openecs.example.web", name = "Web" },
  hint = "Type a URL, such as http://127.0.0.1:47201/, and press Return to fetch it; ws://127.0.0.1:47201/echo opens a WebSocket, which echoes each line, and bye closes it",
  depends = { fetch = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "fetch.panel" } } } } },
  },
}
