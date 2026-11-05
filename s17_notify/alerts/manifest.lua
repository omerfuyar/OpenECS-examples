---@type ecs.Manifest
return {
  name = "alerts",
  version = "0.1.0",
  api = 2,
  description = "Sends desktop notifications and shows a tray icon with the notify plugin",
  depends = { notify = "0.1", draw = "0.1" },
  type = "lua",
}
