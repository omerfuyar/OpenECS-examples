-- The smallest plugin: one panel type that fills itself with one colour.
-- A panel type is a kind of panel. The core makes a panel of it each time one opens, and arranges the panels.

local ecs = require("ecs") -- each plugin gets its own ecs table, the plugin interface; there is no global ecs

ecs.log.info("The plugin loads.") -- this file runs once, when the plugin loads; log lines go to the terminal and the log file

-- register panel types while the plugin loads, not later
ecs.panel.registerType({
  name = "hello.greeting", -- the type's name: the plugin's name, a dot, and a name of its own
  title = "Greeting",      -- what the panel's tab shows

  -- the core calls it when a panel of the type opens; what it returns is the panel's state, which the other functions get
  create = function(panel)
    ecs.log.info("A greeting opens.")
    return { panel = panel }
  end,

  -- the core calls it only when the panel needs drawing: when it is shown, when its size changes, and after panel:redraw()
  -- the surface is the panel's pixels, valid only during this call
  draw = function(_, surface)
    ecs.log.info(("The greeting draws itself, %d by %d pixels."):format(surface.width, surface.height))

    -- a colour is ARGB: alpha, red, green and blue, one byte each, so 0xFF5E81AC is an opaque blue
    surface:fill(0, 0, surface.width, surface.height, 0xFF5E81AC)
  end,

  -- the core calls it when the panel closes, after which the panel's state is gone
  destroy = function()
    ecs.log.info("A greeting closes.")
  end,
})
