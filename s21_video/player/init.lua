-- A panel that plays a video file with the video standard plugin: MPEG-1 video with its MP2 sound, here two seconds of colour bars and a tone.
-- video.open reads the file and shows its first frame; video:play plays it, frames and sound together, and video:draw draws its frame with draw.

local ecs = require("ecs")
local draw = require("draw")
local video = require("video")

local SEEK_STEP = 0.5

ecs.panel.registerType({
  name = "panel",
  title = "Player",
  -- a playing video changes every frame, so the panel draws every frame while it shows
  continuous = true,

  create = function(panel)
    -- a plugin reads its own files by its folder
    local clip = assert(video.open(ecs.plugin.folder .. "sample.mpg"))
    return { panel = panel, clip = clip }
  end,

  destroy = function(state)
    -- free closes the file and stops the sound at once, in place of waiting for the garbage collector
    state.clip:free()
  end,

  event = function(state, event)
    local clip = state.clip

    if event.type == "keyDown" and event.key == "Space" then
      if clip:playing() then clip:pause() else clip:play() end
    elseif event.type == "keyDown" and (event.key == "Left" or event.key == "Right") then
      clip:seek(clip:time() + (event.key == "Right" and SEEK_STEP or -SEEK_STEP))
    end
  end,

  draw = function(state, surface)
    surface:fill(0, 0, surface.width, surface.height, "background")
    local clip = state.clip
    local width, height = surface.width / surface.scale, surface.height / surface.scale - 40
    local videoWidth, videoHeight = clip:size()

    -- the frame keeps its shape, as large as the panel allows
    local fit = math.min(width / videoWidth, height / videoHeight)
    clip:draw(surface, (width - videoWidth * fit) / 2, (height - videoHeight * fit) / 2, videoWidth * fit, videoHeight * fit)

    local status = ("%s  %.1f / %.1f s"):format(clip:playing() and "Playing" or "Paused", clip:time(), clip:duration())
    draw.text(surface, draw.font("ui"), status, 16, height + 10, 18, "text")
  end,

  -- what the test reads
  saveState = function(state)
    local width, height = state.clip:size()
    return { playing = state.clip:playing(), time = state.clip:time(), duration = state.clip:duration(), width = width, height = height }
  end,
})
