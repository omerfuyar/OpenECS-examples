---@type ecs.Manifest
return {
  name = "notes",
  version = "0.1.0",
  api = 4,
  description = "A tool of notes, whose folder the files panel shows",
  depends = { files = "0.1", ui = "0.1" },
  type = "lua",
}
