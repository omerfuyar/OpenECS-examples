-- the viewer with the setting ui.gpu off passes the same test as on the GPU: the image's colours, which draw draws from the image's pixels,
-- and the text's line numbers
local viewer = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "test.lua")

return {
  preset = "preset_pixels.lua",
  run = viewer.run,
}
