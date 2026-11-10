---@type ecs.Manifest
return {
  name = "broken",
  version = "0.1.0",
  api = 2,
  description = "A plugin whose code fails when it starts, so enabling it leaves it disabled",
  type = "lua",
}
