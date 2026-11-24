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

-- a plugin gives its own functions a key after the core prefix, Alt+W, then C, and an entry in the tool's menu Tools
ecs.key.bind("prefix", "C", "counter.count")
ecs.app.addMenuEntry("counter.count")

-- each panel's state is an object of Counter, whose functions are methods
local Counter = {}
Counter.__index = Counter

function Counter.create(panel)
  panels[panel] = true
  return setmetatable({ panel = panel }, Counter)
end

function Counter:destroy()
  ui.forget(self.panel)
  panels[self.panel] = nil
end

function Counter:saveState()
  return { count = count }
end

function Counter:draw(surface)
  ui.show(self.panel, surface, ui.text(("Counted %d times"):format(count), { size = 20 }))
end

function Counter:event(event)
  ui.event(self.panel, event)
end

ecs.panel.registerType({
  name = "panel",
  title = "Counter",
  create = Counter.create,
  destroy = Counter.destroy,
  saveState = Counter.saveState,
  draw = Counter.draw,
  event = Counter.event,
})
