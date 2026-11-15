-- Run it with: OpenECS --fresh --preset examples/s5_files/preset.lua
---@type ecs.Preset
return {
  format = 3,
  name = "files",
  version = "0.1.0",
  app = { id = "openecs.example.files", name = "Files" },
  hint = "Click a note to see its first line, and double-click it to open it; type a name and press New to make a note, or Rename or Delete the chosen file",
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
