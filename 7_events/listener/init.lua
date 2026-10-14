-- Panels that show the ticks of the ticker plugin, and how many panels opened. Events connect plugins that do not call each other.

local ecs = require("ecs")

local listeners = {} -- every open listener, by its panel
local opened = 0

local function show(listener)
  listener.panel.title = ("Ticks %d, panels %d%s"):format(listener.ticks, opened, listener.greeted and ", greeted" or "")
end

-- an event's value is data, and handles and bytes too: this one names a panel by its handle, and carries bytes with a zero among them
ecs.event.declare("opened", "A listener opened: its panel, and a mark of two bytes")

ecs.event.subscribe("listener.opened", function(_, value)
  local listener = listeners[value.panel]

  -- the handle comes back as the same handle, and the bytes as the same string
  if listener and value.mark == "\0\255" then
    listener.greeted = true
    show(listener)
  end
end)

-- subscribe after the plugin that declares the event has loaded; the subscription lasts until it is cancelled
ecs.event.subscribe("ticker.tick", function(_, ticks)
  for _, listener in pairs(listeners) do
    listener.ticks = ticks
    show(listener)
  end
end)

-- the core's events start with "ecs."; ecs.panelOpened's value names the panel and its type
ecs.event.subscribe("ecs.panelOpened", function(_, value)
  opened = opened + 1
  ecs.log.debug(("A %s opened."):format(value.type))
end)

ecs.panel.registerType({
  name = "panel",
  title = "Listener",

  create = function(panel)
    local listener = { panel = panel, ticks = 0 }
    listeners[panel] = listener
    ecs.event.emit("listener.opened", { panel = panel, mark = "\0\255" })
    return listener
  end,

  destroy = function(listener)
    listeners[listener.panel] = nil
  end,

  draw = function(_, surface)
    surface:fill(0, 0, surface.width, surface.height, "#3B4252")
  end,
})
