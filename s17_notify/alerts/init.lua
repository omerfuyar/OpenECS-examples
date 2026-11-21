-- A panel that sends desktop notifications and shows a tray icon, with the notify standard plugin.
-- The system shows a notification as it decides, and may not show it at all, such as in a do-not-disturb mode, or on a desktop without
-- a notification service. What the user clicks, a notification, its buttons or the tray's menu, comes back as notify's events.

local ecs = require("ecs")
local draw = require("draw")
local notify = require("notify")

local panels = {} -- every open panel's state
local lines = {} -- what happened, newest last

local function note(text)
  lines[#lines + 1] = text

  for _, state in pairs(panels) do
    state.panel:redraw()
  end
end

-- each event's value names what was clicked: a notification by its id and its button, a tray by its name and its entry
ecs.event.subscribe("notify.action", function(_, value)
  note(("notification %d: %s"):format(value.id, value.action))
end)

ecs.event.subscribe("notify.trayEntry", function(_, value)
  if value.entry == "quit" then
    ecs.app.quit()
  end

  note(("tray %s: %s%s"):format(value.tray, value.entry, value.checked ~= nil and (value.checked and " on" or " off") or ""))
end)

ecs.event.subscribe("notify.trayClicked", function(_, value)
  note("tray " .. value.tray .. " clicked")
end)

-- the tray icon stays while its handle is kept; a plugin keeps it in a variable of its own, so it is not collected
local tray, problem = notify.tray({
  name = "alerts",
  icon = "resources/sample.png", -- a relative path starts at the executable's folder
  tooltip = "Alerts",
  entries = {
    { id = "hello", label = "Say hello" },
    { id = "mute", label = "Mute", checked = false },
    {}, -- a separator
    { id = "quit", label = "Quit" },
  },
})
note(tray and "The tray icon is shown" or ("No tray icon: " .. problem))

-- each panel's state is an object of Alerts, whose functions are methods
local Alerts = {}
Alerts.__index = Alerts

function Alerts:send()
  local id, why = notify.send({
    title = "Alerts",
    message = ("Notification number %d"):format(self.sent + 1),
    buttons = { { id = "yes", label = "Yes" }, { id = "no", label = "No" } },
  })

  self.sent += 1
  note(id and ("sent notification " .. id) or ("not sent: " .. why))
  self.answered = id ~= nil or type(why) == "string"
end

function Alerts.create(panel)
  local state = setmetatable({ panel = panel, sent = 0 }, Alerts)
  panels[panel] = state
  return state
end

function Alerts:destroy()
  panels[self.panel] = nil
end

function Alerts:event(event)
  if event.type == "keyDown" and event.key == "Return" then
    self:send()
  end
end

function Alerts:draw(surface)
  surface:fill(0, 0, surface.width, surface.height, "background")
  local font, y = draw.font("ui"), 16
  draw.text(surface, font, "Return sends a notification", 16, y, 18, "text")

  for i = math.max(1, #lines - 8), #lines do
    y += 26
    draw.text(surface, font, lines[i], 16, y, 18, "textDim")
  end
end

-- what the test reads
function Alerts:saveState()
  return { sent = self.sent, answered = self.answered }
end

ecs.panel.registerType({
  name = "panel",
  title = "Alerts",

  create = Alerts.create,

  destroy = Alerts.destroy,

  event = Alerts.event,

  draw = Alerts.draw,

  saveState = Alerts.saveState,
})
