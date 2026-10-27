-- A native plugin whose panel draws with the GPU through the gpu standard plugin. The build compiles every C file of the folder into the plugin's library.
---@type ecs.Manifest
return {
  name = "lights_c",
  version = "0.1.0",
  api = 1,
  description = "A panel that draws with the GPU in C: tiles and a moving light, with the gpu plugin's functions",
  type = "native",
  depends = { gpu = "0.1" },
}
