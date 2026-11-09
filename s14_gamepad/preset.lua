-- Run it with: OpenECS --preset examples/s14_gamepad/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "gamepad",
  version = "0.1.0",
  app = { id = "openecs.example.gamepad", name = "Gamepad" },
  hint = "Plug in a gamepad, or press Space for a virtual one, then press its buttons and move its sticks",
  depends = { pad = "0.1" },
  -- the panel reads the gamepads even while another program has the focus, as the tests have no focus
  settings = { ["gamepad.background"] = true },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "pad.panel" } } } } },
  },
}
