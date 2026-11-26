-- Run it with: OpenECS --preset examples/c6_keys/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "keys",
  version = "0.1.0",
  app = { id = "openecs.example.keys", name = "Keys" },
  hint = "Up and Down step the number, and Shift+Up and Shift+Down too; Ctrl+0, or Alt+W then Z, resets every panel",
  depends = { stepper = "0.1" },
  pluginsDir = ".",
  -- a keys table: keys for the whole tool run any function by name; prefix adds keys after the core prefix (Alt+W);
  -- a panel type's table changes its keys, winning over the plugin's defaults; and a plugin's table binds keys in all of its panel types,
  -- where a panel type's own key wins: the plugin's Shift+Up would step down, and loses to the panel type's
  keys = {
    ["Ctrl+0"] = "stepper.resetAll",
    prefix = { Z = "stepper.resetAll" },
    ["stepper.panel"] = { ["Shift+Up"] = "stepper.up" },
    stepper = { ["Shift+Up"] = "stepper.down", ["Shift+Down"] = "stepper.down" },
  },
  workspaces = {
    { name = "Main",
      windows = {
        { split = "horizontal",
          { panels = { { type = "stepper.panel" } } },
          { panels = { { type = "stepper.panel" } } },
        },
      },
    },
  },
}
