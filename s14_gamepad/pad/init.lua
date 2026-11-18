-- A panel that shows every gamepad that is plugged in, with the gamepad standard plugin: the buttons that are down and where the sticks are.
-- The plugin tells what changes as events, so the panel redraws only then; a plugin may also read a gamepad when it wants, such as each frame of a game.
-- The panel draws each gamepad: its triggers, sticks and buttons, which light up as they are used.
-- Space on the panel plugs in a virtual gamepad, which the keyboard drives.

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

-- the virtual gamepad's keys: A, B, X and Y press its buttons, the arrows move its left stick, I, J, K and L its right stick, and Q and E pull its triggers
local BUTTONS = { A = "a", B = "b", X = "x", Y = "y" }
local AXES = {
  Left = { "leftx", -1 },
  Right = { "leftx", 1 },
  Up = { "lefty", -1 },
  Down = { "lefty", 1 },
  J = { "rightx", -1 },
  L = { "rightx", 1 },
  I = { "righty", -1 },
  K = { "righty", 1 },
  Q = { "lefttrigger", 1 },
  E = { "righttrigger", 1 },
}

-- a gamepad's picture, in units of a 400 by 220 box that draw scales to the panel
local FACE = { { "y", 0, -1, "Y" }, { "a", 0, 1, "A" }, { "x", -1, 0, "X" }, { "b", 1, 0, "B" } }
local DPAD = { { "dpup", 0, -1 }, { "dpdown", 0, 1 }, { "dpleft", -1, 0 }, { "dpright", 1, 0 } }
local MIDDLE = { { "back", 165 }, { "guide", 200 }, { "start", 235 } }

-- draws one gamepad in a box at x, y, whose units are scale layout units
local function drawPad(surface, font, pad, x, y, scale)
  local function at(u, v)
    return x + u * scale, y + v * scale
  end

  local function color(down)
    return down and "accent" or "tab"
  end

  -- a trigger is a bar that fills as it is pulled, from 0 to 1, and a shoulder a button under it
  for _, side in ipairs({ { "left", 60 }, { "right", 260 } }) do
    local bx, by = at(side[2], 0)
    draw.rounded(surface, bx, by, 80 * scale, 14 * scale, 4 * scale, "tab")
    draw.rounded(surface, bx, by, 80 * scale * pad:axis(side[1] .. "trigger"), 14 * scale, 4 * scale, "accent")
    bx, by = at(side[2], 20)
    draw.rounded(surface, bx, by, 80 * scale, 12 * scale, 6 * scale, color(pad:button(side[1] .. "shoulder")))
  end

  local bx, by = at(20, 40)
  draw.roundedOutline(surface, bx, by, 360 * scale, 175 * scale, 50 * scale, 2 * scale, "textDim")

  -- a stick is a dot that moves in its ring, and is filled while the stick is pressed down
  for _, stick in ipairs({ { "left", 110, 95 }, { "right", 250, 165 } }) do
    local cx, cy = at(stick[2], stick[3])
    local name = stick[1]
    draw.circle(surface, cx, cy, 30 * scale, 2 * scale, "textDim")
    local dx, dy = pad:axis(name .. "x") * 20 * scale, pad:axis(name .. "y") * 20 * scale
    draw.circle(surface, cx + dx, cy + dy, 12 * scale, 0, color(pad:button(name .. "stick")))
  end

  for _, arrow in ipairs(DPAD) do
    local cx, cy = at(150 + arrow[2] * 20, 165 + arrow[3] * 20)
    draw.fill(surface, cx - 9 * scale, cy - 9 * scale, 18 * scale, 18 * scale, color(pad:button(arrow[1])))
  end

  for _, button in ipairs(FACE) do
    local cx, cy = at(290 + button[2] * 24, 95 + button[3] * 24)
    draw.circle(surface, cx, cy, 11 * scale, 0, color(pad:button(button[1])))
    local width = draw.measure(font, button[4], 13 * scale, surface.scale)
    draw.text(surface, font, button[4], cx - width / 2, cy - 8 * scale, 13 * scale, "text")
  end

  for _, button in ipairs(MIDDLE) do
    local cx, cy = at(button[2], 80)
    draw.rounded(surface, cx - 12 * scale, cy - 5 * scale, 24 * scale, 10 * scale, 5 * scale, color(pad:button(button[1])))
  end
end

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
      elseif AXES[event.key] then
        virtual:move(AXES[event.key][1], down and AXES[event.key][2] or 0)
      end
    end
  end,

  draw = function(state, surface)
    surface:fill(0, 0, surface.width, surface.height, "background")
    local font = draw.font("ui")
    local width, height = surface.width / surface.scale, surface.height / surface.scale
    local y = 12

    if next(pads) == nil then
      draw.text(surface, font, "No gamepad; press Space for a virtual one", 16, y, 18, "textDim")
      y = y + 30
    end

    -- each gamepad gets an equal share of the height, with its name above its picture
    local count = 0

    for _ in pairs(pads) do
      count = count + 1
    end

    local share = count > 0 and (height - y - 40) / count or 0

    for _, pad in pairs(pads) do
      draw.text(surface, font, pad:name(), 16, y, 18, "text")
      local scale = math.max(0.1, math.min((width - 32) / 400, (share - 34) / 220))
      drawPad(surface, font, pad, (width - 400 * scale) / 2, y + 28, scale)
      y = y + share
    end

    draw.text(surface, font, "Last presses: " .. table.concat(state.presses, ", ", math.max(1, #state.presses - 5)), 16, height - 30, 18, "accent")
  end,

  -- what the test reads
  saveState = function(state)
    local names, triggers = {}, {}

    for _, pad in pairs(pads) do
      names[#names + 1] = pad:name()
      triggers[#triggers + 1] = { pad:axis("lefttrigger"), pad:axis("righttrigger") }
    end

    return { pads = names, presses = state.presses, triggers = triggers }
  end,
})
