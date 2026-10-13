-- A preset in the user's presets folder, ~/.config/openecs/presets/: the launcher lists it by its file's name.
-- The test of the launcher names this folder in place of the user's.
---@type ecs.Preset
return {
  format = 1,
  name = "squares",
  version = "0.1.0",
  app = { id = "openecs.example.squares", name = "Squares" },
  depends = { shapes = "0.1" },
  pluginsDir = "../..",
  workspaces = {
    { name = "Main", windows = { { split = "horizontal", { panels = { { type = "shapes.square" } } }, { panels = { { type = "shapes.frame" } } } } } },
  },
}
