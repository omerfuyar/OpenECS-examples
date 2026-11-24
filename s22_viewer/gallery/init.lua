-- A gallery of its own files, built on the viewer: the viewer plugin shows a file as what it is, with the standard
-- loaders, so the gallery only names the file. An image fills the panel, a sound gets Play and Stop, and a text shows
-- in syntax's colours.

local ecs = require("ecs")
local viewer = require("viewer")

local FILES = { "halves.png", "click.wav", "init.lua" }
local shown = 0

local function step(by)
  shown = (shown + by - 1) % #FILES + 1
  -- open shows the file in the viewer that shows it, or in the first one open, or in a new one
  viewer.open(ecs.plugin.folder .. FILES[shown])
end

local function next()
  step(1)
end

-- a slideshow shows the next file every second while its setting is true; the title bar's button shows it on then
local slideshow

ecs.setting.declare({
  name = "slideshow",
  type = "bool",
  description = "Show the next file every second",
  default = false,
  changed = function()
    if slideshow then
      slideshow:stop()
      slideshow = nil
    end
    if ecs.setting.get("gallery.slideshow") then
      slideshow = ecs.timer.start(1, true, next)
    end
  end,
})

ecs.service.register({
  next = { sig = "void()", doc = "Next File", fn = next },
  previous = { sig = "void()", doc = "Previous File", fn = function() step(-1) end },
  -- setForRun starts and stops the slideshow for this run only, so the next start shows it stopped
  slideshow = {
    sig = "void()",
    doc = "Start or stop the slideshow",
    fn = function()
      ecs.setting.setForRun("gallery.slideshow", not ecs.setting.get("gallery.slideshow"))
    end,
  },
})

-- the first file shows once the layout's panels exist, when the tool has started
ecs.timer.start(0, false, next)
