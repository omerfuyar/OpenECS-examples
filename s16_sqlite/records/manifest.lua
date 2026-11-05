---@type ecs.Manifest
return {
  name = "records",
  version = "0.1.0",
  api = 2,
  description = "Keeps records in a database with the sqlite plugin, and shows them",
  depends = { sqlite = "0.1", draw = "0.1" },
  type = "lua",
}
