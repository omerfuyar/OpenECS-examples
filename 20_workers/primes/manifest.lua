---@type ecs.Manifest
return {
  name = "primes",
  version = "0.1.0",
  api = 1,
  description = "Counts primes with four workers, Lua scripts that run on threads of their own, and shows how far each got",
  depends = { ui = "0.1" },
  type = "lua",
}
