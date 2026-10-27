-- Panels that count clicks with the counter plugin's functions. Every panel adds to the same counter, so each shows the total.
-- It also offers a function of its own, tally.reset.

local ecs = require("ecs")
local draw = require("draw")

-- the counter plugin is written in C; its functions are called from Lua like any other
-- require gives every function of a plugin the manifest depends on; the definition files that OpenECS --definitions writes
-- tell editors their parameters, so they complete and check calls
local counter = require("counter")

local panels = {}

local function redrawAll()
  for panel in pairs(panels) do
    panel:redraw()
  end
end

-- counter keeps this function and calls it with each change, from any plugin; a Lua function becomes a C function pointer for it
counter.watch(function(name, value)
  if name == "clicks" then
    for panel in pairs(panels) do
      panel.title = ("Tally (%d)"):format(value)
    end

    redrawAll()
  end
end)

ecs.panel.registerType({
  name = "panel",
  title = "Tally",

  create = function(panel)
    panels[panel] = true
    return { panel = panel }
  end,

  destroy = function(state)
    panels[state.panel] = nil
  end,

  draw = function(_, surface)
    surface:fill(0, 0, surface.width, surface.height, "background")
    draw.text(surface, draw.font("ui"), ("%d clicks in all"):format(counter.get("clicks")), 24, 24, 24, "text")
  end,

  event = function(state, event)
    if event.type == "pointerDown" then
      counter.add("clicks", 1)
    end
  end,
})

-- register functions while the plugin loads; keys, menus and other plugins run them by name
-- a signature says the result's type, then the parameters' types and names; callers in C rely on it
assert(ecs.service.register({
  reset = {
    sig = "void()",
    doc = "Sets the click counter back to 0",
    fn = function()
      counter.add("clicks", -counter.get("clicks"))
    end,
  },
}))
