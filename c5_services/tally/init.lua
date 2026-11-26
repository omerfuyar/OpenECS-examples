-- Panels that count clicks with the counter plugin's functions. Every panel adds to the same counter, so each shows the total.
-- It also offers a function of its own, tally.reset.

local ecs = require("ecs")
local draw = require("draw")

-- the counter plugin is written in C; its functions are called from Lua like any other
-- require gives every function of a plugin the manifest depends on; the definition files that OpenECS --definitions writes
-- tell editors their parameters, so they complete and check calls
local counter = require("counter")

-- a Lua function fails and checks its arguments as a C one does: ecs.check stops the Lua code at a misuse, the caller's mistake,
-- and a failure, which is not the caller's mistake, returns nil and why, as ecs.fail gives it
local function addTo(name, amount)
  ecs.check(amount > 0, "tally.addTo adds an amount above 0.")

  -- a function that can fail gives nil and why
  local value, reason = counter.add(name, amount)

  if not value then
    return nil, ecs.fail(reason)
  end

  return value
end

-- the plugin's own event, which its panel type redraws on below
ecs.event.declare("changed", "The click counter changed: its new value")

-- counter keeps this function and calls it with each change, from any plugin; a Lua function becomes a C function pointer for it
counter.watch(function(name, value)
  if name == "clicks" then
    ecs.event.emit("tally.changed", value)
  end
end)

-- each panel's state is an object of Tally, whose functions are methods
local Tally = {}
Tally.__index = Tally

function Tally.create(panel)
  return setmetatable({ panel = panel }, Tally)
end

-- the tab's title follows the counter as the panel draws; a panel in a hidden tab draws, and shows the count, when it is shown
function Tally:draw(surface)
  local clicks = counter.get("clicks")
  self.panel.title = ("Tally (%d)"):format(clicks)
  surface:fill(0, 0, surface.width, surface.height, "panel")
  draw.text(surface, draw.font("ui"), ("%d clicks in all"):format(clicks), 24, 24, 24, "text")
end

function Tally:event(event)
  if event.type == "pointerDown" then
    addTo("clicks", 1)
  end
end

ecs.panel.registerType({
  name = "panel",
  title = "Tally",

  -- every panel of the type draws again at each tally.changed, so the plugin keeps no list of its panels
  redrawOn = { "tally.changed" },

  create = Tally.create,

  draw = Tally.draw,

  event = Tally.event,
})

-- register functions while the plugin loads; keys, menus and other plugins run them by name
-- a signature says the result's type, then the parameters' types and names; callers in C rely on it
ecs.service.register({
  reset = {
    sig = "void()",
    doc = "Sets the click counter back to 0",
    fn = function()
      counter.add("clicks", -counter.get("clicks"))
    end,
  },

  -- a function that can fail says why in "out string error", its last parameter
  addTo = {
    sig = "int(string name, int amount, out string error)",
    doc = "Adds clicks to a named counter, and gives its new value",
    fn = addTo,
  },
})
