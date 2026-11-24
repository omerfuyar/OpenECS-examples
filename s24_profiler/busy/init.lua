local ecs = require("ecs")

local draw = require("draw")

local BARS = 40
local WAVES = 400

-- a bar's height, from 0 to 1, sums many waves: Lua work of this plugin, which LuaJIT's samples find in the profile
local function wave(time, bar)
  local sum = 0

  for i = 1, WAVES do
    sum += math.sin(time * 2 + bar / 4 + i * 0.001)
  end

  return (sum / WAVES + 1) / 2
end

-- each panel's state is an object of Busy, whose functions are methods
local Busy = {}
Busy.__index = Busy

function Busy.create()
  return setmetatable({ time = 0 }, Busy)
end

-- a plugin reads the profile too: while ecs.profile is on, ecs.profile.get gives each plugin's own time in the last second, and the Lua
-- functions where it went
function Busy:saveState()
  local profile = ecs.profile.get()
  local seconds, functions = {}, {}

  for _, time in ipairs(profile and profile.plugins or {}) do
    seconds[time.name] = time.seconds
  end

  for _, time in ipairs(profile and profile.functions or {}) do
    if time.plugin == "busy" then
      functions[time.name] = true
    end
  end

  return { measured = profile ~= nil, busy = seconds.busy ~= nil, draw = seconds.draw ~= nil, wave = functions["init.lua:wave"] == true }
end

function Busy:draw(surface, seconds)
  self.time += seconds
  local width, height = surface.width / surface.scale, surface.height / surface.scale
  draw.fill(surface, 0, 0, width, height, "panel")

  -- each bar is a call into draw, a C plugin: the profiler counts that time as draw's, not as this plugin's
  local bar = width / BARS

  for i = 0, BARS - 1 do
    local top = wave(self.time, i) * height
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
