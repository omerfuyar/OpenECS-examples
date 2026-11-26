---@type ecs.Manifest
return {
  name = "tally_c",
  version = "0.1.0",
  api = 4,
  description = "The tally plugin's count and level, written in C, whose changes the history plugin undoes and redoes",
  depends = { ui = "0.1", history = "0.1" },
  type = "native",
}
