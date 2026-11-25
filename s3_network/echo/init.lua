-- A server and a client on this computer, with the net standard plugin. The client sends each typed line, and the server sends it back in capitals.
-- A line that starts with /udp goes in a UDP datagram instead of the TCP connection, and comes back the same way.
-- Nothing in net waits: a timer moves the connections on, taking what arrived and answering it, so the program never stops for the network.

local ecs = require("ecs")
local net = require("net")
local draw = require("draw")

local PORT = 47200
local SIZE = 16

-- a function that can fail outside the plugin, as when the port is taken, gives nil and why, as Lua's io.open does
-- an empty host listens on every address of this computer, so other computers reach it too
local server, reason = net.listen("", PORT)
local client = net.connect("127.0.0.1", PORT)
local accepted -- the server's end of the connection, once the client is accepted
local udpServer = net.udp(PORT) -- UDP ports are apart from TCP ports, so the same number serves both
local udpClient = net.udp(0)    -- port 0: any free port
local log = { server and "Listening on port " .. PORT or reason }

-- 127.0.0.1 listens for this computer's programs only, as a tool does for a program it starts; port 0 picks a free port, which port tells
local localServer = assert(net.listen("127.0.0.1", 0))
local localPort = localServer:port()
local localClient = net.connect("127.0.0.1", localPort)
local localAccepted
local localSent = false
local localAnswer = "" -- what came back from the local server, saved for the test

-- a host that does not resolve gives nil and why
local _, badHost = net.listen("no-such-host.invalid", 0)

-- connectTLS starts a TLS connection: its status is 0 until the handshake is done, and the server's certificate is checked against the system's trusted ones
-- this one goes to a plain server on the next port, which answers in plain text, so its handshake fails, its status becomes -1, and its error says why
local plain = net.listen("", PORT + 1)
local secure = net.connectTLS("127.0.0.1", PORT + 1)
local plainClient
local tls, tlsError = 0, "" -- the TLS connection's status and error, saved for the test

-- listenTLS serves TLS with a certificate and its key; this pair was made for this example, for localhost, and is not secret
-- the certificate is nobody's trusted one, so trust adds it to the client's; the server sends back in capitals what the client sends
local secureServer = net.listenTLS("", PORT + 2, ecs.plugin.folder .. "certificate.pem", ecs.plugin.folder .. "key.pem")
net.trust(ecs.plugin.folder .. "certificate.pem")
local secureClient = net.connectTLS("localhost", PORT + 2)
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
    accepted = server:accept()
  end

  plainClient = plainClient or (plain and plain:accept())

  if plainClient and plainClient:receive(1024) ~= "" then
    plainClient:send("not TLS\n")
  end

  tls, tlsError = secure:status(), secure:error()

  localAccepted = localAccepted or localServer:accept()

  if localAccepted and localAccepted:receive(1024) ~= "" then
    localAccepted:send("local")
  end

  if not localSent and localClient:status() == 1 then
    localSent = localClient:send("?")
  end

  localAnswer = localAnswer .. localClient:receive(1024)

  secureAccepted = secureAccepted or (secureServer and secureServer:accept())

  if secureAccepted then
    local received = secureAccepted:receive(1024)

    if received ~= "" then
      secureAccepted:send(received:upper())
    end
  end

  -- the client sends once its handshake is done, which needs the server's side to move on too
  if not secureSent and secureClient:status() == 1 then
    secureSent = secureClient:send("secret")
  end

  secureAnswer = secureAnswer .. secureClient:receive(1024)

  if accepted then
    local received = accepted:receive(1024)

    if received ~= "" then
      accepted:send(received:upper())
    end
  end

  local answer = client:receive(1024)

  if answer ~= "" then
    add("< " .. answer)
  end

  -- a datagram comes with the address and port it came from, where the answer goes
  if udpServer then
    local datagram, host, port = udpServer:receiveFrom()

    if datagram ~= "" then
      udpServer:sendTo(host, port, datagram:upper())
    end
  end

  if udpClient then
    local datagram = udpClient:receiveFrom()

    if datagram ~= "" then
      add("< udp " .. datagram)
    end
  end
end)

-- each panel's state is an object of Echo, whose functions are methods
local Echo = {}
Echo.__index = Echo

function Echo.create(panel)
  panels[panel] = true
  panel:setTextInput(true)
  return setmetatable({ panel = panel, line = "" }, Echo)
end

function Echo:draw(surface)
  surface:fill(0, 0, surface.width, surface.height, "panel")
  local _, height = draw.font("ui"):measure("Ag", SIZE, surface.scale)
  local lines = math.max(1, math.floor(surface.height / surface.scale / height) - 2)

  -- the last lines of the log, then the line being typed
  for i = math.max(1, #log - lines + 1), #log do
    draw.text(surface, draw.font("ui"), log[i], 12, 12 + (i - math.max(1, #log - lines + 1)) * height, SIZE, "text")
  end

  draw.text(surface, draw.font("ui"), "> " .. self.line, 12, 12 + lines * height, SIZE, "accent")
end

function Echo:event(event)
  if event.type == "text" then
    self.line ..= event.text
  elseif event.type == "keyDown" and event.key == "Return" and self.line ~= "" then
    local datagram = self.line:match("^/udp (.+)")

    -- sendTo queues a datagram, which may be lost on the way; send queues data and gives false while the client is not connected yet
    if datagram then
      add(udpClient and udpClient:sendTo("127.0.0.1", PORT, datagram) and "> udp " .. datagram or "Cannot send by UDP")
    elseif client:status() == 1 and client:send(self.line) then
      add("> " .. self.line)
    else
      add("Not connected yet")
    end

    self.line = ""
  else
    return
  end

  self.panel:redraw()
end

function Echo:destroy()
  panels[self.panel] = nil
end

ecs.panel.registerType({
  name = "panel",
  title = "Echo",

  create = Echo.create,

  draw = Echo.draw,

  event = Echo.event,

  destroy = Echo.destroy,
})

-- the log is the plugin's saved state, so the test can read it; the timer stops before the program exits
ecs.plugin.register({
  stateVersion = 1,
  saveState = function()
    return { log = log, tls = tls, tlsError = tlsError, secure = secureAnswer, connected = client:status() == 1,
      localPort = localPort, localAnswer = localAnswer, badHost = badHost }
  end,
  restoreState = function() end,
  destroy = function()
    timer:stop()
  end,
})
