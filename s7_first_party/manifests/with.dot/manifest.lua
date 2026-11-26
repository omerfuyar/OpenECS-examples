-- Not valid: the names that a plugin registers are its name, a dot and a local name, so its own name has no dot
---@type ecs.Manifest
return {
  name = "with.dot",
  version = "0.1.0",
  api = 4,
  type = "lua",
}
