-- Run it with: OpenECS --fresh --preset examples/s22_files_panel/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "files panel",
  version = "0.1.0",
  app = { id = "openecs.example.filesPanel", name = "Files panel" },
  hint = "Click a file twice to open it; type a name and press New to make a note, or Rename or Delete the chosen file",
  depends = { notes = "0.1", files = "0.1" },
  pluginsDir = ".",
  workspaces = {
    {
      name = "Main",
      windows = {
        {
          split = "horizontal",
          { share = 1, panels = { { type = "files.tree" } } },
          { share = 1, panels = { { type = "notes.opened" } } },
        },
      },
    },
  },
}
