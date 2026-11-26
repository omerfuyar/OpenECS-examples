local ecs = require("ecs")

local ui = require("ui")

local count = 0

-- the plugin's own event: each panel of its type draws again when it comes
ecs.event.declare("counted", "The count went up: the new count")

-- a function that takes no arguments, or the focused panel, can be bound to a key; the key list lists it with its description
ecs.service.register({
  count = {
    sig = "void()",
    doc = "Count one more",
    fn = function()
      count += 1
      ecs.event.emit("counter.counted", count)
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
  return setmetatable({ panel = panel }, Counter)
end

function Counter:saveState()
  return { count = count }
end

function Counter:view()
  return ui.text(("Counted %d times"):format(count), { size = 20 })
end

ecs.panel.registerType(ui.panelType({
  name = "panel",
  title = "Counter",
  redrawOn = { "counter.counted" },
  create = Counter.create,
  saveState = Counter.saveState,
  view = Counter.view,
}))
