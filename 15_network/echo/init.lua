-- A server and a client on this computer, with the net standard plugin. The client sends each typed line, and the server sends it back in capitals.
-- Nothing in net waits: a timer moves the connections on, taking what arrived and answering it, so the program never stops for the network.

local ecs = require("ecs")
local net = require("net")
local draw = require("draw")

local PORT = 47200
local SIZE = 16

local server = net.listen(PORT) -- nil if the port is taken
local client = net.connect("127.0.0.1", PORT)
local accepted -- the server's end of the connection, once the client is accepted
local log = { server and "Listening on port " .. PORT or "Cannot listen on port " .. PORT }
local panels = {} -- the open panels, drawn again when the log changes

local function add(line)
  log[#log + 1] = line

  for panel in pairs(panels) do
    panel:redraw()
  end
end

-- every 50 ms: accept the client, answer what the server got, and log what the client got
local timer = ecs.timer.start(0.05, true, function()
  if server and not accepted then
    accepted = net.accept(server)
  end

  if accepted then
    local received = net.receive(accepted, 1024)

    if received ~= "" then
      net.send(accepted, received:upper())
    end
  end

  local answer = net.receive(client, 1024)

  if answer ~= "" then
    add("< " .. answer)
  end
end)

ecs.plugin.onShutdown(function()
  timer:stop()
end)

ecs.panel.registerType({
  name = "echo.panel",
  title = "Echo",

  create = function(panel)
    panels[panel] = true
    panel:setTextInput(true)
    return { panel = panel, line = "" }
  end,

  draw = function(echo, surface)
    surface:fill(0, 0, surface.width, surface.height, draw.color("background"))
    local _, height = draw.measure("Ag", SIZE)
    local lines = math.max(1, math.floor(surface.height / surface.scale / height) - 2)

    -- the last lines of the log, then the line being typed
    for i = math.max(1, #log - lines + 1), #log do
      draw.text(surface, log[i], 12, 12 + (i - math.max(1, #log - lines + 1)) * height, SIZE, draw.color("text"))
    end

    draw.text(surface, "> " .. echo.line, 12, 12 + lines * height, SIZE, draw.color("accent"))
  end,

  event = function(echo, event)
    if event.type == "text" then
      echo.line = echo.line .. event.text
    elseif event.type == "keyDown" and event.key == "Return" and echo.line ~= "" then
      -- send queues the data; it gives false while the client is not connected yet
      if net.status(client) == 1 and net.send(client, echo.line) then
        add("> " .. echo.line)
      else
        add("Not connected yet")
      end

      echo.line = ""
    else
      return
    end

    echo.panel:redraw()
  end,

  destroy = function(echo)
    panels[echo.panel] = nil
  end,
})

-- the log is the plugin's saved state, so the test can read it
ecs.plugin.registerState({
  version = 1,
  save = function()
    return { log = log }
  end,
  restore = function() end,
})
