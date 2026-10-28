---@type ecs.Manifest
return {
  name = "shapes",
  version = "0.1.0",
  api = 2,
  -- the panel list shows the description under the plugin's name
  description = "A square and a frame, in a colour that is a setting",
  depends = { draw = "0.1" },
  type = "lua",
}
