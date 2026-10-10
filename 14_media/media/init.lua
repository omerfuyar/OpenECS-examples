-- A picture that plays a sound when it is clicked: the image standard plugin reads and draws image files, and the audio plugin plays sound files.
-- Both read a file once and keep it, so loading the same path again gives the same picture or sound.

local ecs = require("ecs")
local image = require("image")
local audio = require("audio")

-- a plugin's files are found from its folder
local picture = image.load(ecs.plugin.folder .. "note.svg")
local sound = audio.load(ecs.plugin.folder .. "click.wav")

ecs.panel.registerType({
  name = "media.panel",
  title = "Media",

  create = function(panel)
    return { panel = panel, plays = 0, rect = { 0, 0, 0, 0 }, scale = 1 }
  end,

  draw = function(media, surface)
    surface:fill(0, 0, surface.width, surface.height, 0xFF202020)

    -- the picture is as large as fits the panel, centred, in layout units; an SVG file is drawn sharp at that size
    local width, height = surface.width / surface.scale, surface.height / surface.scale
    local pictureWidth, pictureHeight = image.size(picture)
    local scale = math.min(width / pictureWidth, height / pictureHeight) * 0.8
    local w, h = pictureWidth * scale, pictureHeight * scale
    media.rect = { (width - w) / 2, (height - h) / 2, w, h }
    media.scale = surface.scale
    image.draw(surface, picture, media.rect[1], media.rect[2], w, h)
  end,

  event = function(media, event)
    -- pointer positions are in surface pixels, and the picture's rectangle in layout units
    local x, y, w, h = table.unpack(media.rect)
    local px, py = (event.x or 0) / media.scale, (event.y or 0) / media.scale

    -- a click on the picture plays the sound; each play is a voice, so clicks can overlap
    if event.type == "pointerDown" and px >= x and px <= x + w and py >= y and py <= y + h then
      if audio.play(sound, 0.8, false) > 0 then
        media.plays = media.plays + 1
        media.panel:setTitle(("Media (%d)"):format(media.plays))
      end
    end
  end,

  saveState = function(media)
    return { plays = media.plays }
  end,
})
