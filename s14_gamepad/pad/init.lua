-- A panel that shows every gamepad that is plugged in, with the gamepad standard plugin: the buttons that are down and where the sticks are.
-- The plugin tells what changes as events, so the panel redraws only then; a plugin may also read a gamepad when it wants, such as each frame of a game.
-- Space on the panel plugs in a virtual gamepad, which the keyboard drives: A, B, X and Y press its buttons, and the arrows move its left stick.

local ecs = require("ecs")
local draw = require("draw")
local gamepad = require("gamepad")

local panels = {} -- every open panel's state, to redraw them all
local pads = {} -- every open gamepad, by its id
local virtual -- the virtual gamepad, once Space plugged it in

local function redraw()
  for _, state in pairs(panels) do
    state.panel:redraw()
  end
end

-- opens a gamepad, to read it; one that cannot open is left out
local function add(id)
  if not pads[id] then
    pads[id] = gamepad.open(id)
    redraw()
  end
end

-- an event's value is a table, which gamepad's events fill with the gamepad's id and what changed
ecs.event.subscribe("gamepad.added", function(_, value)
  add(value.id)
end)

ecs.event.subscribe("gamepad.removed", function(_, value)
  pads[value.id] = nil
  redraw()
end)

ecs.event.subscribe("gamepad.button", function(_, value)
  for _, state in pairs(panels) do
    state.presses[#state.presses + 1] = value.button .. (value.down and " down" or " up")
  end

  redraw()
end)

ecs.event.subscribe("gamepad.axis", redraw)

-- the gamepads that were plugged in before the plugin loaded give no event
for _, info in ipairs(gamepad.list()) do
  add(info.id)
end

local BUTTONS = { A = "a", B = "b", X = "x", Y = "y" }
local STICK = { Left = { "leftx", -1 }, Right = { "leftx", 1 }, Up = { "lefty", -1 }, Down = { "lefty", 1 } }

ecs.panel.registerType({
  name = "panel",
  title = "Gamepads",

  create = function(panel)
    local state = { panel = panel, presses = {} }
    panels[panel] = state
    return state
  end,

  destroy = function(state)
    panels[state.panel] = nil
  end,

  event = function(_, event)
    if event.type == "keyDown" and event.key == "Space" and not virtual then
      -- the virtual gamepad shows as any gamepad does: gamepad.added comes, and the panel opens it
      virtual = assert(gamepad.attachVirtual("Keyboard"))
    elseif virtual and (event.type == "keyDown" or event.type == "keyUp") then
      local down = event.type == "keyDown"

      if BUTTONS[event.key] then
        virtual:press(BUTTONS[event.key], down)
      elseif STICK[event.key] then
        virtual:move(STICK[event.key][1], down and STICK[event.key][2] or 0)
      end
    end
  end,

  draw = function(state, surface)
    surface:fill(0, 0, surface.width, surface.height, "background")
    local font, y = draw.font("ui"), 16

    local function show(text, color)
      draw.text(surface, font, text, 16, y, 18, color)
      y = y + 26
    end

    if next(pads) == nil then
      show("No gamepad; press Space for a virtual one", "textDim")
    end

    for _, pad in pairs(pads) do
      local down = {}

      for _, button in ipairs({ "a", "b", "x", "y", "start", "back", "leftshoulder", "rightshoulder" }) do
        if pad:button(button) then
          down[#down + 1] = button
        end
      end

      show(pad:name(), "text")
      show(("  left stick %.2f, %.2f   buttons down: %s"):format(pad:axis("leftx"), pad:axis("lefty"), table.concat(down, " ")), "textDim")
    end

    show("Last presses: " .. table.concat(state.presses, ", ", math.max(1, #state.presses - 5)), "accent")
  end,

  -- what the test reads
  saveState = function(state)
    local names = {}

    for _, pad in pairs(pads) do
      names[#names + 1] = pad:name()
    end

    return { pads = names, presses = state.presses }
  end,
})
