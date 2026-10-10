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

ecs.panel.registerType({
  name = "tally.panel",
  title = "Tally",

  create = function(panel)
    panels[panel] = true
    return { panel = panel }
  end,

  destroy = function(tally)
    panels[tally.panel] = nil
  end,

  draw = function(_, surface)
    surface:fill(0, 0, surface.width, surface.height, draw.color("background"))
    draw.text(surface, ("%d clicks in all"):format(counter.get("clicks")), 24, 24, 24, draw.color("text"))
  end,

  event = function(tally, event)
    if event.type == "pointerDown" then
      tally.panel:setTitle(("Tally (%d)"):format(counter.add("clicks", 1)))
      redrawAll()
    end
  end,
})

-- register functions while the plugin loads; keys, menus and other plugins run them by name
-- a signature says the result's type, then the parameters' types and names; callers in C rely on it
assert(ecs.service.register("tally", {
  reset = {
    sig = "void()",
    doc = "Sets the click counter back to 0",
    fn = function()
      counter.add("clicks", -counter.get("clicks"))
      redrawAll()
    end,
  },
}))
