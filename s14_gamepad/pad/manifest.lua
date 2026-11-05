---@type ecs.Manifest
return {
  name = "pad",
  version = "0.1.0",
  api = 2,
  description = "Shows the buttons and sticks of gamepads with the gamepad plugin",
  depends = { gamepad = "0.1", draw = "0.1" },
  type = "lua",
}
