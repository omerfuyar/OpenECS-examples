-- A number that keys step up and down.

local ecs = require("ecs")

local draw = require("draw") -- the functions of a plugin the manifest depends on

local steppers = {} -- every open stepper, by its panel

local function step(panel, amount)
  local stepper = steppers[panel]

  if stepper then
    stepper.value = stepper.value + amount
    panel.title = ("Stepper (%d)"):format(stepper.value)
    panel:redraw()
  end
end

ecs.panel.registerType({
  name = "panel",
  title = "Stepper",

  create = function(panel)
    local stepper = { panel = panel, value = 0 }
    steppers[panel] = stepper
    return stepper
  end,

  destroy = function(state)
    steppers[state.panel] = nil
  end,

  draw = function(state, surface)
    surface:fill(0, 0, surface.width, surface.height, "background")
    draw.text(surface, draw.font("ui"), tostring(state.value), 24, 24, 48, "text")
  end,

  -- keys that no binding takes come to the focused panel
  event = function(state, event)
    if event.type == "keyDown" and event.key == "Space" then
      step(state.panel, 10)
    end
  end,
})

-- a handle stands for an object of the core or a plugin, here a panel
-- a function that keys run on a panel takes it as handle<ecs.panel>; the key passes the focused panel
assert(ecs.service.register({
  up = { sig = "void(handle<ecs.panel>)", doc = "Step up", fn = function(panel) step(panel, 1) end },
  down = { sig = "void(handle<ecs.panel>)", doc = "Step down", fn = function(panel) step(panel, -1) end },
  resetAll = {
    sig = "void()",
    doc = "Set every stepper to 0",
    fn = function()
      for panel, stepper in pairs(steppers) do
        step(panel, -stepper.value)
      end
    end,
  },
}))

-- bind gives a function a default key, working while a panel of the plugin's type has focus; the function must exist first
-- the preset's keys and the user's settings win over these defaults, as preset.lua shows
assert(ecs.key.bind("stepper.panel", "Up", "stepper.up"))
assert(ecs.key.bind("stepper.panel", "Down", "stepper.down"))

-- the panel's menu (a right click on its tab) shows these functions with their keys
ecs.panel.addMenuEntry("stepper.panel", "stepper.up")
ecs.panel.addMenuEntry("stepper.panel", "stepper.down")
