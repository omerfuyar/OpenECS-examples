-- A greeting whose name, colour and size are settings. The settings window (Alt+W, then ",") shows and changes them.

local ecs = require("ecs")
local draw = require("draw")

local COLORS = { blue = "#5E81AC", green = "#A3BE8C", red = "#BF616A" }

local greetings = {} -- every open greeting, by its panel

local function title()
  return ("Hello, %s (%d)"):format(ecs.setting.get("greeter.name"), ecs.setting.get("greeter.size"))
end

-- runs after a setting's value in effect changes, whichever layer changed it
local function changed()
  for _, greeting in pairs(greetings) do
    greeting.panel.title = title()
    greeting.panel:redraw()
  end
end

-- a setting has a type, and the core takes only values of that type: bool, integer, number, string, choice, key, color, list or table
-- its value in effect comes from the highest of three layers: the default declared here, then the preset, then the user's settings file
-- declare settings while the plugin loads; a setting's name starts with the plugin's name
ecs.setting.declare({ name = "name", type = "string", description = "Who to greet", default = "world", changed = changed })
ecs.setting.declare({ name = "color", type = "choice", description = "Colour of the greeting", default = "blue", choices = { "blue", "green", "red" }, changed = changed })
ecs.setting.declare({ name = "size", type = "integer", description = "Size of the greeting; the wheel changes it", default = 32, changed = changed })
ecs.setting.declare({ name = "background", type = "color", description = "Colour behind the greeting", default = "#2E3440", changed = changed })

-- the core tells every plugin when any setting changes, its own or another's, such as the core's font, which the greeting is drawn in
local heard = {} -- how many times each setting changed, by its full name

ecs.event.subscribe("ecs.settingChanged", function(_, value)
  heard[value.name] = (heard[value.name] or 0) + 1

  if value.name == "ecs.font" then
    changed()
  end
end)

ecs.panel.registerType({
  name = "panel",
  title = "Greeting",

  create = function(panel)
    local greeting = { panel = panel }
    greetings[panel] = greeting
    panel.title = title()
    return greeting
  end,

  destroy = function(greeting)
    greetings[greeting.panel] = nil
  end,

  -- the settings that changed are part of the panel's state, so the test can see them
  saveState = function()
    return { heard = heard }
  end,

  -- get gives the value in effect
  draw = function(_, surface)
    surface:fill(0, 0, surface.width, surface.height, ecs.setting.get("greeter.background"))
    draw.text(surface, draw.font("ui"), "Hello, " .. ecs.setting.get("greeter.name") .. "!", 24, 24, ecs.setting.get("greeter.size"), COLORS[ecs.setting.get("greeter.color")])
  end,

  event = function(_, event)
    if event.type == "wheel" then
      -- set writes the value into the user's settings file, the highest layer; changed runs afterwards, not during this call
      local size = ecs.setting.get("greeter.size") + (event.scrollY > 0 and 2 or -2)
      ecs.setting.set("greeter.size", math.max(8, math.min(96, size)))
    elseif event.type == "pointerDown" then
      -- explain tells which layer a value comes from: "default", "preset" or "user"
      local explanation = assert(ecs.setting.explain("greeter.name"))
      ecs.log.info(("greeter.name is '%s', from the %s layer."):format(explanation.value, explanation.layer))
    end
  end,
})
