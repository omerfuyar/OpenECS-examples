-- A number that keys step up and down.

local ecs = require("ecs")

local draw = require("draw") -- the functions of a plugin the manifest depends on

local steppers = {} -- every open stepper, by its panel

local function step(panel, amount)
  local stepper = steppers[panel]

  if stepper then
    stepper.value = stepper.value + amount
    panel:setTitle(("Stepper (%d)"):format(stepper.value))
    panel:redraw()
  end
end

ecs.panel.registerType({
  name = "stepper.panel",
  title = "Stepper",

  create = function(panel)
    local stepper = { panel = panel, value = 0 }
    steppers[panel] = stepper
    return stepper
  end,

  destroy = function(stepper)
    steppers[stepper.panel] = nil
  end,

  draw = function(stepper, surface)
    surface:fill(0, 0, surface.width, surface.height, draw.color("background"))
    draw.text(surface, tostring(stepper.value), 24, 24, 48, draw.color("text"))
  end,

  -- keys that no binding takes come to the focused panel
  event = function(stepper, event)
    if event.type == "keyDown" and event.key == "Space" then
      step(stepper.panel, 10)
    end
  end,
})

-- a handle stands for an object of the core or a plugin, here a panel
-- a function that keys run on a panel takes it as handle<ecs.panel>; the key passes the focused panel
assert(ecs.service.register("stepper", {
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
assert(ecs.input.bind("stepper.panel", "Up", "stepper.up"))
assert(ecs.input.bind("stepper.panel", "Down", "stepper.down"))

-- the panel's menu (a right click on its tab) shows these functions with their keys
ecs.panel.addMenuEntry("stepper.panel", "stepper.up")
ecs.panel.addMenuEntry("stepper.panel", "stepper.down")
