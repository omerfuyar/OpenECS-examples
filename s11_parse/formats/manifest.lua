---@type ecs.Manifest
return {
  name = "formats",
  version = "0.1.0",
  api = 2,
  description = "Writes a table as JSON, TOML, INI, .env or CSV, and reads the text back, with the parse and ui plugins",
  depends = { parse = "0.1", ui = "0.1" },
  type = "lua",
}
