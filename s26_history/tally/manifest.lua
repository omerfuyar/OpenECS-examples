---@type ecs.Manifest
return {
  name = "tally",
  version = "0.1.0",
  api = 4,
  description = "A count and a level whose changes the history plugin undoes and redoes; tally_c is the same in C",
  depends = { ui = "0.1", history = "0.1" },
  type = "lua",
}
