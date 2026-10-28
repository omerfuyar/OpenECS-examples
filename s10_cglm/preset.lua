-- Run it with: OpenECS --fresh --preset examples/s10_cglm/preset.lua
---@type ecs.Preset
return {
  format = 1,
  name = "cglm",
  version = "0.1.0",
  app = { id = "openecs.example.cglm", name = "Cube" },
  hint = "Drag the cube to turn it; Alt+W, then 2 shows the same cube in C",
  depends = { cube = "0.1", cube_c = "0.1" },
  pluginsDir = ".",
  workspaces = {
    { name = "Main", windows = { { panels = { { type = "cube.panel" } } } } },
    { name = "C",    windows = { { panels = { { type = "cube_c.panel" } } } } },
  },
}
