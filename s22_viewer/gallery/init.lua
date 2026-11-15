-- A gallery of its own files, built on the viewer: the viewer plugin shows a file as what it is, with the standard
-- loaders, so the gallery only names the file. An image fills the panel, a sound gets Play and Stop, and a text shows
-- in syntax's colours.

local ecs = require("ecs")
local viewer = require("viewer")

local FILES = { "halves.png", "click.wav", "init.lua" }
local shown = 0

local function next()
  shown = shown % #FILES + 1
  -- open shows the file in the viewer that shows it, or in the first one open, or in a new one
  viewer.open(ecs.plugin.folder .. FILES[shown])
end

ecs.service.register({
  next = { sig = "void()", doc = "Next File", fn = next },
})

-- the first file shows once the layout's panels exist, when the tool has started
ecs.timer.start(0, false, next)
