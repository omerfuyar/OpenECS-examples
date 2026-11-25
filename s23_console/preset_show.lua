-- two consoles, without the setting console.show: a new one, and one with the state that a session would restore
---@type ecs.Preset
return {
  format = 3,
  name = "console-show",
  version = "0.1.0",
  app = { id = "openecs.example.console-show", name = "Console's levels" },
  depends = { console = "0.1" },
  pluginsDir = ".",
  workspaces = {
    {
      name = "Main",
      windows = {
        {
          split = "horizontal",
          { share = 1, panels = { { type = "console.log" } } },
          { share = 1, panels = { { type = "console.log", state = { show = "error" } } } },
        },
      },
    },
  },
}
