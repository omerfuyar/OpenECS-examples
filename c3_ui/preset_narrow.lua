-- the controls in Lua and in C, each in a narrow panel, side by side, with the controls in Lua again beside them
---@type ecs.Preset
return {
  format = 1,
  name = "ui-narrow",
  version = "0.1.0",
  app = { id = "openecs.example.ui-narrow", name = "Narrow controls" },
  depends = { button = "0.1", button_c = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main",
      windows = {
        { split = "horizontal",
          { size = 140, panels = { { type = "button.panel" } } },
          { size = 140, panels = { { type = "button_c.panel" } } },
          { panels = { { type = "button.panel" } } },
        },
      },
    },
  },
}
