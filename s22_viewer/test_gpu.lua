-- the viewer with the setting ui.gpu on passes the same test as on pixels: the image's colours, which ui draws from a texture on the GPU, and
-- the text's line numbers
local viewer = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "test.lua")

return {
  preset = "preset_gpu.lua",
  run = viewer.run,
}
