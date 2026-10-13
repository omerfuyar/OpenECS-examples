-- A saved session in the user's folder of sessions, ~/.local/share/openecs/sessions/, as OpenECS writes one: the preset's fields, with the panels as they were.
-- The test of the launcher names this folder in place of the user's.
---@type ecs.Session
return {
  format = 1,
  name = "first party",
  version = "0.1.0",
  app = { id = "openecs.example.firstParty", name = "First party" },
  depends = { shapes = "0.1", settings = "0.1", panels = "0.1" },
  pluginsDir = "../..",
  workspaces = {
    {
      name = "Main",
      windows = { { split = "horizontal", { panels = { { type = "shapes.square", id = 1 } } }, { panels = { { type = "shapes.frame", id = 2 } } } } },
      focus = 1,
    },
  },
}
