---@type ecs.Manifest
return {
  name = "counter",
  version = "0.1.0",
  api = 3,
  description = "A function that a key runs, and a panel that shows how many times it ran",
  depends = { ui = "0.1" },
  type = "lua",
}
