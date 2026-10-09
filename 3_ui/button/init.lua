-- A button that counts its clicks, built with the ui standard plugin.
-- A standard plugin ships with OpenECS for other plugins to build on: draw draws shapes and text, and ui builds user interfaces on it.

local ecs = require("ecs")

-- require with a plugin's name gives that plugin's functions; the manifest must depend on it, so it loads first
local ui = require("ui")

ecs.panel.registerType({
  name = "button.panel",
  title = "Button",

  create = function(panel)
    return { panel = panel, clicks = 0 }
  end,

  -- draw runs only when the panel needs drawing; a panel type that draws every frame says continuous = true
  -- ui lays out and draws the elements that draw describes each time, so the panel keeps only its own state
  draw = function(button, surface)
    ui.show(button.panel, surface, ui.column({ padding = 24, gap = 12, align = "center" }, {
      ui.text(("Clicked %d times"):format(button.clicks), { size = 18 }),
      ui.button("Click me", {
        onClick = function()
          button.clicks = button.clicks + 1
          button.panel:setTitle(("Button (%d)"):format(button.clicks))
        end,
      }),
    }))
  end,

  -- the panel's events go to ui, which calls the callbacks of the elements they reach, and asks the core to draw the panel again
  event = function(button, event)
    ui.event(button.panel, event)
  end,

  destroy = function(button)
    ui.forget(button.panel)
  end,
})
