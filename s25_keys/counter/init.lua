local ecs = require("ecs")

local ui = require("ui")

local count = 0
local panels = {}

-- a function that takes no arguments, or the focused panel, can be bound to a key; the key list lists it with its description
ecs.service.register({
  count = {
    sig = "void()",
    doc = "Count one more",
    fn = function()
      count += 1

      for panel in pairs(panels) do
        panel:redraw()
      end
    end,
  },
})

ecs.panel.registerType({
  name = "panel",
  title = "Counter",
  create = function(panel)
    panels[panel] = true
    return { panel = panel }
  end,
  destroy = function(state)
    ui.forget(state.panel)
    panels[state.panel] = nil
  end,
  saveState = function()
    return { count = count }
  end,
  draw = function(state, surface)
    ui.show(state.panel, surface, ui.text(("Counted %d times"):format(count), { size = 20 }))
  end,
  event = function(state, event)
    ui.event(state.panel, event)
  end,
})
