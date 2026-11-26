-- Not valid: a plugin's name is the scope of its keys for all its panels, and prefix is the scope of the keys after the prefix
---@type ecs.Manifest
return {
  name = "prefix",
  version = "0.1.0",
  api = 4,
  type = "lua",
}
