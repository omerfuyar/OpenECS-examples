---@type ecs.Manifest
return {
  name = "fetch",
  version = "0.1.0",
  api = 1,
  description = "Fetches each typed URL with the web plugin, from a small server of its own or from the internet",
  depends = { web = "0.1", net = "0.1", draw = "0.1" },
  type = "lua",
}
