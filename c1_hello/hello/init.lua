-- The smallest plugin: one panel type that fills itself with one colour.
-- A panel type is a kind of panel. The core makes a panel of it each time one opens, and arranges the panels.

local ecs = require("ecs")        -- each plugin gets its own ecs table, the plugin interface; there is no global ecs

ecs.log.info("The plugin loads.") -- this file runs once, when the plugin loads; log lines go to the terminal and the log file

-- a panel's state is an object of a class: a table whose functions are methods, and whose __index is itself,
-- so greeting:draw(surface) finds draw in Greeting
local Greeting = {}
Greeting.__index = Greeting

-- the core calls create each time a panel of the type opens; what it returns is the panel's state, which the other functions get
-- saved is what saveState gave when the session was saved, or nil for a new panel, and version is the stateVersion it was saved with
-- this panel saves nothing, so both are nil; c8_state shows a panel that saves its state
function Greeting.create(panel, saved, version)
  ecs.log.info("A greeting opens.")
  return setmetatable({ panel = panel }, Greeting) -- a table that keeps the panel, such as to set panel.title later
end

-- the core calls draw only when the panel needs drawing: when it is shown, when its size changes, and after panel:redraw()
-- the core calls it as draw(state, surface, seconds), which is state:draw(surface, seconds): self is the state that create gave
-- the surface is the panel's pixels, valid only during this call
-- seconds is the time passed since the last draw in seconds
function Greeting:draw(surface, seconds)
  ecs.log.info(("The greeting draws itself, %d by %d pixels."):format(surface.width, surface.height))

  -- a colour is a text: "#RRGGBB", "#RRGGBBAA" with alpha, or a colour of the theme, such as "accent"
  -- editors complete the theme's colours, as the type ecs.Color in include/ecs.lua lists them
  surface:fill(0, 0, surface.width, surface.height, "#5E81AC")
end

-- the core calls destroy when the panel closes, after which the panel's state is gone
function Greeting:destroy()
  ecs.log.info("A greeting closes.")
end

-- register panel types while the plugin loads, not later
ecs.panel.registerType({
  name = "greeting",  -- the type's local name; the core adds the plugin's name, so presets know it as "hello.greeting"
  title = "Greeting", -- what the panel's tab shows
  create = Greeting.create,
  draw = Greeting.draw,
  destroy = Greeting.destroy,
})
