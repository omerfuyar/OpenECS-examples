-- A picture that plays a sound when it is clicked. Loaders read files, and executors use what they read:
-- the image plugin reads an image file into an image of the draw plugin, which draws it; the audio plugin reads a sound file into a sound of the mixer plugin, which plays it.
-- A loader also writes what an executor holds back to a file: image.save writes an image of draw.
-- R turns the picture and F fades it, S writes it to a file, B plays a tone, T plays a tune read from its file as it plays, M muffles the tune, E plays a tone with an echo, and V turns a reverb on and off.
-- A spinner in the corner is an animated GIF file.

local ecs = require("ecs")
local ffi = require("ffi")
local image = require("image")
local draw = require("draw")
local audio = require("audio")
local mixer = require("mixer")

-- a plugin's files are found from its folder
local PICTURE = ecs.plugin.folder .. "note.svg"
local sound = audio.load(ecs.plugin.folder .. "click.wav")

-- a tone made here, rather than read from a file: a stream is a sound whose samples are given while it plays
local RATE = 48000

local function tone(seconds, pitch)
  local stream = mixer.newStream(1, RATE)
  -- the samples are floats in an FFI array, whose bytes C reads without a copy
  local count = math.floor(seconds * RATE)
  local samples = ffi.new("float[?]", count)

  for i = 0, count - 1 do
    samples[i] = 0.2 * math.sin(2 * math.pi * pitch * (i + 1) / RATE)
  end

  -- queue adds samples to the end; a synthesizer would queue more from a timer while the sound's queued says little waits
  stream:queue(samples)
  return stream
end

-- an animated GIF file gives its frames, each an image and the seconds it shows for
local SPINNER = ecs.plugin.folder .. "spinner.gif"

-- the picture's own size, from reading it at a scale of 1
local naturalWidth, naturalHeight = image.load(PICTURE, 1):size()

-- each panel's state is an object of Media, whose functions are methods
local Media = {}
Media.__index = Media

function Media.create(panel)
  local media = setmetatable({ panel = panel, plays = 0, rect = { 0, 0, 0, 0 }, scale = 1, readAt = 0, smooth = false, angle = 0, faded = false }, Media)
  media.frames, media.frame = image.loadFrames(SPINNER, 1), 1

  -- each frame shows for its own seconds, then the next one does
  local function advance()
    media.timer = ecs.timer.start(math.max(media.frames[media.frame].seconds, 0.02), false, function()
      media.frame = media.frame % #media.frames + 1
      panel:redraw()
      advance()
    end)
  end

  advance()
  return media
end

function Media:destroy()
  self.timer:stop()
end

function Media:draw(surface)
  surface:fill(0, 0, surface.width, surface.height, "#202020")

  -- the picture is as large as fits the panel, centred, in layout units
  local width, height = surface.width / surface.scale, surface.height / surface.scale
  local scale = math.min(width / naturalWidth, height / naturalHeight) * 0.8
  local w, h = naturalWidth * scale, naturalHeight * scale
  self.rect = { (width - w) / 2, (height - h) / 2, w, h }
  self.scale = surface.scale

  -- an SVG file is read again at each new size, in pixels, so it is drawn sharp
  if self.readAt ~= scale * surface.scale then
    self.readAt = scale * surface.scale
    self.picture = image.load(PICTURE, self.readAt)
  end

  -- draw also draws shapes: a frame with rounded corners, whose edges are smooth, behind the picture
  local x, y = self.rect[1] - 8, self.rect[2] - 8
  draw.rounded(surface, x, y, w + 16, h + 16, 16, "#3A3F4B")

  -- R turns the picture and F fades it; draw.image is the quicker way to draw it as it is
  if self.angle == 0 and not self.faded then
    draw.image(surface, self.picture, self.rect[1], self.rect[2], w, h)
  else
    draw.imageTransformed(surface, self.picture, self.rect[1], self.rect[2], w, h, self.angle, self.faded and "#FFFFFF60" or "#FFFFFF")
  end

  draw.image(surface, self.frames[self.frame].image, 8, 8, 32, 32)

  -- two points on either side of the note's left stem, which a half turn swaps
  self.probes = {}

  for i, across in ipairs({ 0.42, 0.58 }) do
    self.probes[i] = surface:getPixel(math.floor((self.rect[1] + across * w) * surface.scale), math.floor((self.rect[2] + 0.5 * h) * surface.scale))
  end

  -- a smooth edge has pixels that the frame covers only in part, so their colour is between the frame's and the background's
  local seen = {}

  -- the corner's curved edge crosses the square of 8 units at the corner, before the picture starts; a square, as one line of pixels may
  -- pass over the edge where the frame starts between pixels
  local left, top = math.floor(x * surface.scale), math.floor(y * surface.scale)

  for i = 0, math.floor(7 * surface.scale) do
    for j = 0, math.floor(7 * surface.scale) do
      seen[surface:getPixel(left + i, top + j)] = true
    end
  end

  seen["#202020FF"], seen["#3A3F4BFF"] = nil, nil
  self.smooth = next(seen) ~= nil
end

function Media:event(event)
  -- pointer positions are in surface pixels, and the picture's rectangle in layout units
  local x, y, w, h = table.unpack(self.rect)
  local px, py = (event.x or 0) / self.scale, (event.y or 0) / self.scale

  -- a click on the picture plays the sound; each play is a voice, so clicks can overlap
  -- B plays a tone to the left: finish says that no more samples come, so its voice ends once they have played
  if event.type == "keyDown" and event.key == "B" then
    local stream = tone(0.3, 440)
    self.toneQueued = stream:queued()
    stream:finish()
    self.tone = stream:play(1, false)
    mixer.pan(self.tone, -0.8)
  end

  -- E plays a tone with an echo: what it played a fifth of a second ago comes back, softer each time, so it rings on after the tone ends
  if event.type == "keyDown" and event.key == "E" then
    local stream = tone(0.3, 660)
    stream:finish()
    self.echoed = stream:play(1, false)
    mixer.echo(self.echoed, 0.2, 0.3, 0.6)
  end

  -- S writes the picture as drawn to a PNG file in this plugin's folder, and reads it back, which gives the same pixels
  if event.type == "keyDown" and (event.key == "R" or event.key == "F") then
    self.angle = event.key == "R" and (self.angle + 90) % 360 or self.angle
    self.faded = self.faded ~= (event.key == "F")
    self.panel:redraw()
  end

  if event.type == "keyDown" and event.key == "S" and self.picture ~= nil then
    local path = ecs.plugin.folder .. "ignore.picture.png"
    local saved = image.save(self.picture, path) and image.load(path, 1)
    self.saved = saved and saved:pixels() == self.picture:pixels() or false
    os.remove(path)
  end

  -- M muffles the tune, as if it played behind a wall: a low-pass filter cuts its sounds above 600 hertz; a second M takes the filter away
  if event.type == "keyDown" and event.key == "M" and self.tune ~= nil then
    self.muffled = not self.muffled
    mixer.filter(self.tune, self.muffled and 600 or 0, 0)
  end

  -- V adds a reverb to everything that plays, as in a room, or takes it away; reverb gives false when there is no output
  if event.type == "keyDown" and event.key == "V" then
    local on = not self.reverb
    self.reverb = mixer.reverb(on and 0.3 or 0, 0.6) and on
  end

  -- T streams a tune: audio reads a long file a piece at a time while it plays, instead of whole
  if event.type == "keyDown" and event.key == "T" then
    local stream = audio.stream(ecs.plugin.folder .. "tune.wav")
    self.tuneQueued = stream:queued()
    self.tune = stream:play(0.8, false)
  end

  if event.type == "pointerDown" and px >= x and px <= x + w and py >= y and py <= y + h then
    if sound:play(0.8, false) > 0 then
      self.plays += 1
      self.panel.title = ("Media (%d)"):format(self.plays)
    end
  end
end

function Media:saveState()
  return { plays = self.plays, smooth = self.smooth, toneQueued = self.toneQueued, tonePlaying = self.tone ~= nil and mixer.playing(self.tone), saved = self.saved, probes = self.probes, frames = #self.frames, frameSeconds = self.frames[1].seconds, frame = self.frame, tuneQueued = self.tuneQueued, tunePlaying = self.tune ~= nil and mixer.playing(self.tune), reverb = self.reverb == true, muffled = self.muffled == true, echoPlaying = self.echoed ~= nil and mixer.playing(self.echoed) }
end

ecs.panel.registerType({
  name = "panel",
  title = "Media",

  create = Media.create,

  destroy = Media.destroy,

  draw = Media.draw,

  event = Media.event,

  saveState = Media.saveState,
})
