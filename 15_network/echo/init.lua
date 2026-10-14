-- A server and a client on this computer, with the net standard plugin. The client sends each typed line, and the server sends it back in capitals.
-- A line that starts with /udp goes in a UDP datagram instead of the TCP connection, and comes back the same way.
-- Nothing in net waits: a timer moves the connections on, taking what arrived and answering it, so the program never stops for the network.

local ecs = require("ecs")
local net = require("net")
local draw = require("draw")

local PORT = 47200
local SIZE = 16

local server = net.listen(PORT) -- nil if the port is taken
local client = net.connect("127.0.0.1", PORT)
local accepted -- the server's end of the connection, once the client is accepted
local udpServer = net.udp(PORT) -- UDP ports are apart from TCP ports, so the same number serves both
local udpClient = net.udp(0)    -- port 0: any free port
local log = { server and "Listening on port " .. PORT or "Cannot listen on port " .. PORT }

-- connectTls starts a TLS connection: its status is 0 until the handshake is done, and the server's certificate is checked against the system's trusted ones
-- this one goes to a plain server on the next port, which answers in plain text, so its handshake fails and its status becomes -1
local plain = net.listen(PORT + 1)
local secure = net.connectTls("127.0.0.1", PORT + 1)
local plainClient
local tls = 0 -- the TLS connection's status, saved for the test

-- listenTls serves TLS with a certificate and its key; this pair was made for this example, for localhost, and is not secret
-- the certificate is nobody's trusted one, so trust adds it to the client's; the server sends back in capitals what the client sends
local secureServer = net.listenTls(PORT + 2, ecs.plugin.folder .. "certificate.pem", ecs.plugin.folder .. "key.pem")
net.trust(ecs.plugin.folder .. "certificate.pem")
local secureClient = net.connectTls("localhost", PORT + 2)
local secureAccepted
local secureSent = false
local secureAnswer = "" -- what came back over TLS, saved for the test
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

  plainClient = plainClient or (plain and net.accept(plain))

  if plainClient and net.receive(plainClient, 1024) ~= "" then
    net.send(plainClient, "not TLS\n")
  end

  tls = net.status(secure)

  secureAccepted = secureAccepted or (secureServer and net.accept(secureServer))

  if secureAccepted then
    local received = net.receive(secureAccepted, 1024)

    if received ~= "" then
      net.send(secureAccepted, received:upper())
    end
  end

  -- the client sends once its handshake is done, which needs the server's side to move on too
  if not secureSent and net.status(secureClient) == 1 then
    secureSent = net.send(secureClient, "secret")
  end

  secureAnswer = secureAnswer .. net.receive(secureClient, 1024)

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

  -- a datagram comes with the address and port it came from, where the answer goes
  if udpServer then
    local datagram, host, port = net.receiveFrom(udpServer)

    if datagram ~= "" then
      net.sendTo(udpServer, host, port, datagram:upper())
    end
  end

  if udpClient then
    local datagram = net.receiveFrom(udpClient)

    if datagram ~= "" then
      add("< udp " .. datagram)
    end
  end
end)

ecs.panel.registerType({
  name = "panel",
  title = "Echo",

  create = function(panel)
    panels[panel] = true
    panel:setTextInput(true)
    return { panel = panel, line = "" }
  end,

  draw = function(echo, surface)
    surface:fill(0, 0, surface.width, surface.height, "background")
    local _, height = draw.measure(draw.font("ui"), "Ag", SIZE)
    local lines = math.max(1, math.floor(surface.height / surface.scale / height) - 2)

    -- the last lines of the log, then the line being typed
    for i = math.max(1, #log - lines + 1), #log do
      draw.text(surface, draw.font("ui"), log[i], 12, 12 + (i - math.max(1, #log - lines + 1)) * height, SIZE, "text")
    end

    draw.text(surface, draw.font("ui"), "> " .. echo.line, 12, 12 + lines * height, SIZE, "accent")
  end,

  event = function(echo, event)
    if event.type == "text" then
      echo.line = echo.line .. event.text
    elseif event.type == "keyDown" and event.key == "Return" and echo.line ~= "" then
      local datagram = echo.line:match("^/udp (.+)")

      -- sendTo queues a datagram, which may be lost on the way; send queues data and gives false while the client is not connected yet
      if datagram then
        add(udpClient and net.sendTo(udpClient, "127.0.0.1", PORT, datagram) and "> udp " .. datagram or "Cannot send by UDP")
      elseif net.status(client) == 1 and net.send(client, echo.line) then
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

-- the log is the plugin's saved state, so the test can read it; the timer stops before the program exits
ecs.plugin.register({
  stateVersion = 1,
  saveState = function()
    return { log = log, tls = tls, secure = secureAnswer }
  end,
  restoreState = function() end,
  destroy = function()
    timer:stop()
  end,
})
