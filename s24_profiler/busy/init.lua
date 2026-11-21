local ecs = require("ecs")

local draw = require("draw")

local BARS = 40

-- each panel's state is an object of Busy, whose functions are methods
local Busy = {}
Busy.__index = Busy

function Busy.create()
  return setmetatable({ time = 0 }, Busy)
end

-- a plugin reads the profile too: while ecs.profile is on, ecs.profile.get gives each plugin's own time in the last second
function Busy:saveState()
  local profile = ecs.profile.get()
  local seconds = {}

  for _, time in ipairs(profile and profile.plugins or {}) do
    seconds[time.name] = time.seconds
  end

  return { measured = profile ~= nil, busy = seconds.busy ~= nil, draw = seconds.draw ~= nil }
end

function Busy:draw(surface, seconds)
  self.time += seconds
  local width, height = surface.width / surface.scale, surface.height / surface.scale
  draw.fill(surface, 0, 0, width, height, "background")

  -- each bar is a call into draw, a C plugin: the profiler counts that time as draw's, not as this plugin's
  local bar = width / BARS

  for i = 0, BARS - 1 do
    local top = (math.sin(self.time * 2 + i / 4) + 1) / 2 * height
    draw.fill(surface, i * bar, top, bar - 1, height - top, "accent")
  end
end

ecs.panel.registerType({
  name = "panel",
  title = "Busy",
  -- the panel draws every frame, so the profiler always has something to measure
  continuous = true,
  create = Busy.create,
  saveState = Busy.saveState,
  draw = Busy.draw,
})
