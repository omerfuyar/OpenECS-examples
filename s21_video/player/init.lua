-- A panel that plays a video file with the video standard plugin: MPEG-1 video with its MP2 sound, here two seconds of colour bars and a tone.
-- video.open reads the file and shows its first frame; video:play plays it, frames and sound together, and video:draw draws its frame with draw.

local ecs = require("ecs")
local draw = require("draw")
local video = require("video")

local SEEK_STEP = 0.5

-- each panel's state is an object of Player, whose functions are methods
local Player = {}
Player.__index = Player

function Player.create(panel)
  -- a plugin reads its own files by its folder
  local clip = assert(video.open(ecs.plugin.folder .. "sample.mpg"))
  return setmetatable({ panel = panel, clip = clip }, Player)
end

function Player:destroy()
  -- free closes the file and stops the sound at once, in place of waiting for the garbage collector
  self.clip:free()
end

function Player:event(event)
  local clip = self.clip

  if event.type == "keyDown" and event.key == "Space" then
    if clip:playing() then clip:pause() else clip:play() end
  elseif event.type == "keyDown" and (event.key == "Left" or event.key == "Right") then
    clip:seek(clip:time() + (event.key == "Right" and SEEK_STEP or -SEEK_STEP))
  end
end

function Player:draw(surface)
  surface:fill(0, 0, surface.width, surface.height, "panel")
  local clip = self.clip
  local width, height = surface.width / surface.scale, surface.height / surface.scale - 40
  local videoWidth, videoHeight = clip:size()

  -- the frame keeps its shape, as large as the panel allows
  local fit = math.min(width / videoWidth, height / videoHeight)
  clip:draw(surface, (width - videoWidth * fit) / 2, (height - videoHeight * fit) / 2, videoWidth * fit, videoHeight * fit)

  local status = ("%s  %.1f / %.1f s"):format(clip:playing() and "Playing" or "Paused", clip:time(), clip:duration())
  draw.text(surface, draw.font("ui"), status, 16, height + 10, 18, "text")
end

-- what the test reads
function Player:saveState()
  local width, height = self.clip:size()
  return { playing = self.clip:playing(), time = self.clip:time(), duration = self.clip:duration(), width = width, height = height }
end

ecs.panel.registerType({
  name = "panel",
  title = "Player",
  -- a playing video changes every frame, so the panel draws every frame while it shows
  continuous = true,

  create = Player.create,

  destroy = Player.destroy,

  event = Player.event,

  draw = Player.draw,

  saveState = Player.saveState,
})
