-- Run it with: OpenECS --fresh --preset examples/s25_keys/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "keys",
  version = "0.1.0",
  app = { id = "openecs.example.keys", name = "Keys" },
  hint = "Ctrl+J counts; the key list changes, removes and adds keys in your settings, and Alt+W, then K opens it in any tool",
  depends = { counter = "0.1", keys = "0.1" },
  pluginsDir = ".",
  -- the preset binds a key for the whole tool; the user's settings, which the key list writes, win over it
  keys = { ["Ctrl+J"] = "counter.count" },
  workspaces = {
    {
      name = "Main",
      windows = {
        {
          split = "horizontal",
          { share = 1, panels = { { type = "counter.panel" } } },
          { share = 2, panels = { { type = "keys.list" } } },
        },
      },
    },
  },
}
