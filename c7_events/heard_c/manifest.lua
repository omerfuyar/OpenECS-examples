-- A native plugin that hears the log through the core's event ecs.logged. The build compiles every C file of the folder into the plugin's library.
---@type ecs.Manifest
return {
  name = "heard_c",
  version = "0.1.0",
  api = 3,
  description = "A panel that counts the warnings it hears in the log",
  type = "native",
}
