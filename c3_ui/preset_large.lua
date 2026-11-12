-- the controls of preset.lua, a quarter larger: ecs.scale gives each panel's surface a scale of 1.25, so ui lays the elements out in layout units as
-- before and draws each unit as 1.25 pixels
---@type ecs.Preset
return {
  format = 1,
  name = "ui-large",
  version = "0.1.0",
  app = { id = "openecs.example.ui-large", name = "Larger controls" },
  depends = { button = "0.1", button_c = "0.1" },
  pluginsDir = ".",
  settings = { ["ecs.scale"] = 1.25 },
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "button.panel" } } } } },
  },
}
