-- The smallest plugin: one panel type that fills itself with one colour.
-- A panel type is a kind of panel. The core makes a panel of it each time one opens, and arranges the panels.

local ecs = require("ecs")        -- each plugin gets its own ecs table, the plugin interface; there is no global ecs

ecs.log.info("The plugin loads.") -- this file runs once, when the plugin loads; log lines go to the terminal and the log file

-- register panel types while the plugin loads, not later
ecs.panel.registerType({
  -- todo maybe auto append plugin name and dot to the start of this kind of names, that will take responsibility from the user
  name = "hello.greeting", -- the type's name: the plugin's name, a dot, and a name of its own
  title = "Greeting",      -- what the panel's tab shows

  -- the core calls create when a panel of the type created, opened for the first time; what it returns is the panel's state, which the other functions get
  -- todo what is saved ???
  -- todo what is version ???
  create = function(panel, saved, version)
    ecs.log.info("A greeting opens.")
    return { myPanel = panel } -- this allocates memory to keep custom state, panel on the left hand side is the panel of this plugin
  end,

  -- the core calls draw only when the panel needs drawing: when it is shown, when its size changes, and after panel:redraw()
  -- state is the table returned in the create function
  -- the surface is the panel's pixels, valid only during this call
  -- seconds is the time passed since the last draw in seconds
  draw = function(state, surface, seconds)
    ecs.log.info(("The greeting draws itself, %d by %d pixels."):format(surface.width, surface.height))

    -- a colour is ARGB: alpha, red, green and blue, one byte each, so 0xFF5E81AC is an opaque blue
    surface:fill(0, 0, surface.width, surface.height, 0xFF5E81AC) -- todo make all colors either 0x... or "#..."
  end,

  -- the core calls destroy when the panel closes, after which the panel's state is gone
  destroy = function(state)
    ecs.log.info("A greeting closes.")
  end,
})
