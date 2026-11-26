---@type ecs.Manifest
return {
  name = "lender",
  version = "0.1.0",
  api = 4,
  description = "Gives the C canvas a brush and frees it while Lua still holds its handle, so the test checks what the handle does then",
  depends = { sketch_c = "0.1" },
  type = "lua",
}
