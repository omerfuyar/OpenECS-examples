local ecs = require("ecs")

local draw = require("draw")

local BARS = 40

ecs.panel.registerType({
  name = "panel",
  title = "Busy",
  -- the panel draws every frame, so the profiler always has something to measure
  continuous = true,
  create = function()
    return { time = 0 }
  end,
  -- a plugin reads the profile too: while ecs.profile is on, ecs.profile.get gives each plugin's own time in the last second
  saveState = function()
    local profile = ecs.profile.get()
    local seconds = {}

    for _, time in ipairs(profile and profile.plugins or {}) do
      seconds[time.name] = time.seconds
    end

    return { measured = profile ~= nil, busy = seconds.busy ~= nil, draw = seconds.draw ~= nil }
  end,
  draw = function(state, surface, seconds)
    state.time += seconds
    local width, height = surface.width / surface.scale, surface.height / surface.scale
    draw.fill(surface, 0, 0, width, height, "background")

    -- each bar is a call into draw, a C plugin: the profiler counts that time as draw's, not as this plugin's
    local bar = width / BARS

    for i = 0, BARS - 1 do
      local top = (math.sin(state.time * 2 + i / 4) + 1) / 2 * height
      draw.fill(surface, i * bar, top, bar - 1, height - top, "accent")
    end
  end,
})
