-- A picture that plays a sound when it is clicked. Loaders read files, and executors use what they read:
-- the image plugin reads an image file into an image of the draw plugin, which draws it; the audio plugin reads a sound file into a sound of the mixer plugin, which plays it.

local ecs = require("ecs")
local image = require("image")
local draw = require("draw")
local audio = require("audio")
local mixer = require("mixer")

-- a plugin's files are found from its folder
local PICTURE = ecs.plugin.folder .. "note.svg"
local sound = audio.load(ecs.plugin.folder .. "click.wav")

-- the picture's own size, from reading it at a scale of 1
local naturalWidth, naturalHeight = draw.imageSize(image.load(PICTURE, 1))

ecs.panel.registerType({
  name = "panel",
  title = "Media",

  create = function(panel)
    return { panel = panel, plays = 0, rect = { 0, 0, 0, 0 }, scale = 1, readAt = 0, smooth = false }
  end,

  draw = function(media, surface)
    surface:fill(0, 0, surface.width, surface.height, "#202020")

    -- the picture is as large as fits the panel, centred, in layout units
    local width, height = surface.width / surface.scale, surface.height / surface.scale
    local scale = math.min(width / naturalWidth, height / naturalHeight) * 0.8
    local w, h = naturalWidth * scale, naturalHeight * scale
    media.rect = { (width - w) / 2, (height - h) / 2, w, h }
    media.scale = surface.scale

    -- an SVG file is read again at each new size, in pixels, so it is drawn sharp
    if media.readAt ~= scale * surface.scale then
      media.readAt = scale * surface.scale
      media.picture = image.load(PICTURE, media.readAt)
    end

    -- draw also draws shapes: a frame with rounded corners, whose edges are smooth, behind the picture
    local x, y = media.rect[1] - 8, media.rect[2] - 8
    draw.rounded(surface, x, y, w + 16, h + 16, 16, "#3A3F4B")
    draw.image(surface, media.picture, media.rect[1], media.rect[2], w, h)

    -- a smooth edge has pixels that the frame covers only in part, so their colour is between the frame's and the background's
    local seen = {}

    -- the corner's edge crosses the diagonal from the corner about 5 units in, before the picture starts at 8
    for i = 0, math.floor(7 * surface.scale) do
      seen[surface:getPixel(math.floor(x * surface.scale) + i, math.floor(y * surface.scale) + i)] = true
    end

    seen["#202020FF"], seen["#3A3F4BFF"] = nil, nil
    media.smooth = next(seen) ~= nil
  end,

  event = function(media, event)
    -- pointer positions are in surface pixels, and the picture's rectangle in layout units
    local x, y, w, h = table.unpack(media.rect)
    local px, py = (event.x or 0) / media.scale, (event.y or 0) / media.scale

    -- a click on the picture plays the sound; each play is a voice, so clicks can overlap
    if event.type == "pointerDown" and px >= x and px <= x + w and py >= y and py <= y + h then
      if mixer.play(sound, 0.8, false) > 0 then
        media.plays = media.plays + 1
        media.panel.title = ("Media (%d)"):format(media.plays)
      end
    end
  end,

  saveState = function(media)
    return { plays = media.plays, smooth = media.smooth }
  end,
})
