-- A native plugin whose panel draws with SDL's GPU API. The build compiles every C file of the folder into the plugin's library.
---@type ecs.Manifest
return {
  name = "lights",
  version = "0.1.0",
  api = 1,
  description = "A panel that draws with the GPU: it clears its texture and copies small pictures into it",
  -- the built-in sdl plugin gives the GPU device; its version is SDL's
  depends = { sdl = "3.4" },
  type = "native",
}
