---@type ecs.Manifest
return {
  name = "help",
  version = "0.1.0",
  api = 2,
  description = "Shows a Markdown file as a help panel with the markdown plugin",
  depends = { markdown = "0.1", ui = "0.1" },
  type = "lua",
}
