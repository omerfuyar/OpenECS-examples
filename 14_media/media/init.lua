-- A picture that plays a sound when it is clicked. Loaders read files, and executors use what they read:
-- the image plugin reads an image file into an image of the draw plugin, which draws it; the audio plugin reads a sound file into a sound of the mixer plugin, which plays it.
-- A loader also writes what an executor holds back to a file: image.save writes an image of draw.
-- R turns the picture and F fades it, S writes it to a file, B plays a tone, T plays a tune read from its file as it plays, M muffles the tune, E plays a tone with an echo, and V turns a reverb on and off.
-- A spinner in the corner is an animated GIF file.

local ecs = require("ecs")
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
  local samples = {}

  for i = 1, math.floor(seconds * RATE) do
    samples[i] = string.pack("f", 0.2 * math.sin(2 * math.pi * pitch * i / RATE))
  end

  -- queue adds samples to the end; a synthesizer would queue more from a timer while the sound's queued says little waits
  stream:queue(table.concat(samples))
  return stream
end

-- an animated GIF file gives its frames, each an image and the seconds it shows for
local SPINNER = ecs.plugin.folder .. "spinner.gif"

-- the picture's own size, from reading it at a scale of 1
local naturalWidth, naturalHeight = image.load(PICTURE, 1):size()

ecs.panel.registerType({
  name = "panel",
  title = "Media",

  create = function(panel)
    local media = { panel = panel, plays = 0, rect = { 0, 0, 0, 0 }, scale = 1, readAt = 0, smooth = false, angle = 0, faded = false }
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
  end,

  destroy = function(state)
    state.timer:stop()
  end,

  draw = function(state, surface)
    surface:fill(0, 0, surface.width, surface.height, "#202020")

    -- the picture is as large as fits the panel, centred, in layout units
    local width, height = surface.width / surface.scale, surface.height / surface.scale
    local scale = math.min(width / naturalWidth, height / naturalHeight) * 0.8
    local w, h = naturalWidth * scale, naturalHeight * scale
    state.rect = { (width - w) / 2, (height - h) / 2, w, h }
    state.scale = surface.scale

    -- an SVG file is read again at each new size, in pixels, so it is drawn sharp
    if state.readAt ~= scale * surface.scale then
      state.readAt = scale * surface.scale
      state.picture = image.load(PICTURE, state.readAt)
    end

    -- draw also draws shapes: a frame with rounded corners, whose edges are smooth, behind the picture
    local x, y = state.rect[1] - 8, state.rect[2] - 8
    draw.rounded(surface, x, y, w + 16, h + 16, 16, "#3A3F4B")

    -- R turns the picture and F fades it; draw.image is the quicker way to draw it as it is
    if state.angle == 0 and not state.faded then
      draw.image(surface, state.picture, state.rect[1], state.rect[2], w, h)
    else
      draw.imageTransformed(surface, state.picture, state.rect[1], state.rect[2], w, h, state.angle, state.faded and "#FFFFFF60" or "#FFFFFF")
    end

    draw.image(surface, state.frames[state.frame].image, 8, 8, 32, 32)

    -- two points on either side of the note's left stem, which a half turn swaps
    state.probes = {}

    for i, across in ipairs({ 0.42, 0.58 }) do
      state.probes[i] = surface:getPixel(math.floor((state.rect[1] + across * w) * surface.scale), math.floor((state.rect[2] + 0.5 * h) * surface.scale))
    end

    -- a smooth edge has pixels that the frame covers only in part, so their colour is between the frame's and the background's
    local seen = {}

    -- the corner's edge crosses the diagonal from the corner about 5 units in, before the picture starts at 8
    for i = 0, math.floor(7 * surface.scale) do
      seen[surface:getPixel(math.floor(x * surface.scale) + i, math.floor(y * surface.scale) + i)] = true
    end

    seen["#202020FF"], seen["#3A3F4BFF"] = nil, nil
    state.smooth = next(seen) ~= nil
  end,

  event = function(state, event)
    -- pointer positions are in surface pixels, and the picture's rectangle in layout units
    local x, y, w, h = table.unpack(state.rect)
    local px, py = (event.x or 0) / state.scale, (event.y or 0) / state.scale

    -- a click on the picture plays the sound; each play is a voice, so clicks can overlap
    -- B plays a tone to the left: finish says that no more samples come, so its voice ends once they have played
    if event.type == "keyDown" and event.key == "B" then
      local stream = tone(0.3, 440)
      state.toneQueued = stream:queued()
      stream:finish()
      state.tone = stream:play(1, false)
      mixer.pan(state.tone, -0.8)
    end

    -- E plays a tone with an echo: what it played a fifth of a second ago comes back, softer each time, so it rings on after the tone ends
    if event.type == "keyDown" and event.key == "E" then
      local stream = tone(0.3, 660)
      stream:finish()
      state.echoed = stream:play(1, false)
      mixer.echo(state.echoed, 0.2, 0.3, 0.6)
    end

    -- S writes the picture as drawn to a PNG file in this plugin's folder, and reads it back, which gives the same pixels
    if event.type == "keyDown" and (event.key == "R" or event.key == "F") then
      state.angle = event.key == "R" and (state.angle + 90) % 360 or state.angle
      state.faded = state.faded ~= (event.key == "F")
      state.panel:redraw()
    end

    if event.type == "keyDown" and event.key == "S" and state.picture ~= nil then
      local path = ecs.plugin.folder .. "ignore.picture.png"
      local saved = image.save(state.picture, path) and image.load(path, 1)
      state.saved = saved and saved:pixels() == state.picture:pixels() or false
      os.remove(path)
    end

    -- M muffles the tune, as if it played behind a wall: a low-pass filter cuts its sounds above 600 hertz; a second M takes the filter away
    if event.type == "keyDown" and event.key == "M" and state.tune ~= nil then
      state.muffled = not state.muffled
      mixer.filter(state.tune, state.muffled and 600 or 0, 0)
    end

    -- V adds a reverb to everything that plays, as in a room, or takes it away; reverb gives false when there is no output
    if event.type == "keyDown" and event.key == "V" then
      local on = not state.reverb
      state.reverb = mixer.reverb(on and 0.3 or 0, 0.6) and on
    end

    -- T streams a tune: audio reads a long file a piece at a time while it plays, instead of whole
    if event.type == "keyDown" and event.key == "T" then
      local stream = audio.stream(ecs.plugin.folder .. "tune.wav")
      state.tuneQueued = stream:queued()
      state.tune = stream:play(0.8, false)
    end

    if event.type == "pointerDown" and px >= x and px <= x + w and py >= y and py <= y + h then
      if sound:play(0.8, false) > 0 then
        state.plays = state.plays + 1
        state.panel.title = ("Media (%d)"):format(state.plays)
      end
    end
  end,

  saveState = function(state)
    return { plays = state.plays, smooth = state.smooth, toneQueued = state.toneQueued, tonePlaying = state.tone ~= nil and mixer.playing(state.tone), saved = state.saved, probes = state.probes, frames = #state.frames, frameSeconds = state.frames[1].seconds, frame = state.frame, tuneQueued = state.tuneQueued, tunePlaying = state.tune ~= nil and mixer.playing(state.tune), reverb = state.reverb == true, muffled = state.muffled == true, echoPlaying = state.echoed ~= nil and mixer.playing(state.echoed) }
  end,
})
