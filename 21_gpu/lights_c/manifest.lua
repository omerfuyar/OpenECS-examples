-- A native plugin whose panel draws with SDL's GPU API. The build compiles every C file of the folder into the plugin's library.
---@type ecs.Manifest
return {
  name = "lights_c",
  version = "0.1.0",
  api = 1,
  description = "A panel that draws with the GPU in C: it clears its texture and copies small pictures into it with SDL's GPU API",
  type = "native",
}
