---@type ecs.Manifest
return {
  name = "bonus",
  version = "0.1.0",
  api = 3,
  description = "Adds a bonus of clicks through tally's Lua function, from C",
  depends = { tally = "0.1" },
  type = "native",
}
