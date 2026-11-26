-- The preset of test-manifests.lua: the lister, from the folder manifests, beside two plugins whose manifests are not valid.
---@type ecs.Preset
return {
  format = 3,
  name = "manifests",
  version = "0.1.0",
  app = { id = "openecs.example.manifests", name = "Manifests" },
  hint = "The lister lists the plugins; the two whose manifests are not valid are left out",
  depends = { lister = "0.1" },
  pluginsDir = "manifests",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "lister.panel" } } } } },
  },
}
