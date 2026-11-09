-- Run it with: OpenECS --preset examples/s17_notify/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "notify",
  version = "0.1.0",
  app = { id = "openecs.example.notify", name = "Notify" },
  hint = "Return sends a notification with two buttons; the tray icon's menu counts its clicks",
  depends = { alerts = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "alerts.panel" } } } } },
  },
}
