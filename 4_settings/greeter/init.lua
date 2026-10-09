-- A greeting whose name, colour and size are settings. The settings window (Alt+W, then ",") shows and changes them.

local ecs = require("ecs")
local draw = require("draw")

local COLORS = { blue = "#5E81AC", green = "#A3BE8C", red = "#BF616A" }

local greetings = {} -- every open greeting, by its panel

local function title()
  return ("Hello, %s (%d)"):format(ecs.settings.get("greeter.name"), ecs.settings.get("greeter.size"))
end

-- runs after a setting's value in effect changes, whichever layer changed it
local function changed()
  for _, greeting in pairs(greetings) do
    greeting.panel:setTitle(title())
    greeting.panel:redraw()
  end
end

-- a setting has a type, and the core takes only values of that type: bool, integer, number, string, choice, key, color, list or table
-- its value in effect comes from the highest of three layers: the default declared here, then the preset, then the user's settings file
-- declare settings while the plugin loads; a setting's name starts with the plugin's name
ecs.settings.declare({ name = "greeter.name", type = "string", description = "Who to greet", default = "world", changed = changed })
ecs.settings.declare({ name = "greeter.color", type = "choice", description = "Colour of the greeting", default = "blue", choices = { "blue", "green", "red" }, changed = changed })
ecs.settings.declare({ name = "greeter.size", type = "integer", description = "Size of the greeting; the wheel changes it", default = 32, changed = changed })
ecs.settings.declare({ name = "greeter.background", type = "color", description = "Colour behind the greeting", default = "#2E3440", changed = changed })

ecs.panel.registerType({
  name = "greeter.panel",
  title = "Greeting",

  create = function(panel)
    local greeting = { panel = panel }
    greetings[panel] = greeting
    panel:setTitle(title())
    return greeting
  end,

  destroy = function(greeting)
    greetings[greeting.panel] = nil
  end,

  -- get gives the value in effect
  draw = function(_, surface)
    surface:fill(0, 0, surface.width, surface.height, draw.color(ecs.settings.get("greeter.background")))
    draw.text(surface, "Hello, " .. ecs.settings.get("greeter.name") .. "!", 24, 24, ecs.settings.get("greeter.size"), draw.color(COLORS[ecs.settings.get("greeter.color")]))
  end,

  event = function(_, event)
    if event.type == "wheel" then
      -- set writes the value into the user's settings file, the highest layer; changed runs afterwards, not during this call
      local size = ecs.settings.get("greeter.size") + (event.wheelY > 0 and 2 or -2)
      ecs.settings.set("greeter.size", math.max(8, math.min(96, size)))
    elseif event.type == "pointerDown" then
      -- explain tells which layer a value comes from: "default", "preset" or "user"
      local explanation = assert(ecs.settings.explain("greeter.name"))
      ecs.log.info(("greeter.name is '%s', from the %s layer."):format(explanation.value, explanation.layer))
    end
  end,
})
