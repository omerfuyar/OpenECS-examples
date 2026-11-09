---@type ecs.Manifest
return {
  name = "logfilter",
  version = "0.1.0",
  api = 2,
  description = "Filters a log's lines with the regex plugin",
  depends = { regex = "0.1", ui = "0.1" },
  type = "lua",
}
