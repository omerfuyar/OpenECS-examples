-- Panels that show the ticks of the ticker plugin, and how many panels opened. Events connect plugins that do not call each other.

local ecs = require("ecs")

local listeners = {} -- every open listener, by its panel
local opened = 0
local renewed = 0 -- the ticks that the subscription below heard, which it renews at each

-- each panel's state is an object of Listener, whose functions are methods
local Listener = {}
Listener.__index = Listener

function Listener:show()
  self.panel.title = ("Ticks %d, panels %d%s"):format(self.ticks, opened, self.greeted and ", greeted" or "")
end

-- an event's value is data, and handles and bytes too: this one names a panel by its handle, carries bytes with a zero among them,
-- and a handle of this plugin's own type, which stands for a Lua value
ecs.event.declare("opened", "A listener opened: its panel, a mark of two bytes, and a note")
ecs.handle.registerType("note")

-- a note's text, which is its value; as a method of the type, Lua writes note:text()
ecs.service.register({
  text = { sig = "string(handle<listener.note>)", doc = "Gives a note's text", fn = function(note) return ecs.handle.value(note, "note") end },
})
ecs.handle.addMethod("note", "text", "text")

ecs.event.subscribe("listener.opened", function(_, value)
  local listener = listeners[value.panel]

  -- the handle comes back as the same handle, and the bytes as the same string; a handle in an event's value lives until the event is delivered,
  -- even when nothing else keeps it, so the note's value is still there
  if listener and value.mark == "\0\255" and value.note:text() == "hello" then
    listener.greeted = true
    listener:show()
  end
end)

-- a handler may free handles while events wait: here a note that nothing keeps, collected after the event before it was delivered
ecs.event.declare("noted", "A listener opened, after listener.opened")
local noted = 0

ecs.event.subscribe("listener.noted", function()
  local _ = ecs.handle.new("note", "gone")
  _ = nil
  collectgarbage()
  noted += 1
end)

-- subscribe after the plugin that declares the event has loaded; the subscription lasts until it is cancelled
ecs.event.subscribe("ticker.tick", function(_, ticks)
  for _, listener in pairs(listeners) do
    listener.ticks = ticks
    listener:show()
  end
end)

-- a handler may cancel its subscription and subscribe again: the new subscription hears the next tick, not the one being delivered,
-- so each tick is heard once
local renewing

local function renew()
  renewed += 1
  renewing:unsubscribe()
  renewing = ecs.event.subscribe("ticker.tick", renew)
end

renewing = ecs.event.subscribe("ticker.tick", renew)

-- the core's events start with "ecs."; ecs.panelOpened's value names the panel and its type
ecs.event.subscribe("ecs.panelOpened", function(_, value)
  opened += 1
  ecs.log.debug(("A %s opened."):format(value.type))
end)

function Listener.create(panel)
  local listener = setmetatable({ panel = panel, ticks = 0 }, Listener)
  listeners[panel] = listener
  ecs.event.emit("listener.opened", { panel = panel, mark = "\0\255", note = ecs.handle.new("note", "hello") })

  ecs.event.emit("listener.noted")

  -- nothing but the event keeps the note now, and a collection before the delivery does not take it
  collectgarbage()
  return listener
end

function Listener:destroy()
  listeners[self.panel] = nil
end

function Listener:saveState()
  return { ticks = self.ticks, renewed = renewed, noted = noted }
end

function Listener:draw(surface)
  surface:fill(0, 0, surface.width, surface.height, "#3B4252")
end

ecs.panel.registerType({
  name = "panel",
  title = "Listener",

  create = Listener.create,

  destroy = Listener.destroy,

  saveState = Listener.saveState,

  draw = Listener.draw,
})
