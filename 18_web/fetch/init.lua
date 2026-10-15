-- Fetches each typed URL with the web standard plugin, and shows the answer's status, type and first line.
-- So the example works without the internet, the plugin also serves two pages on this computer with net, at http://127.0.0.1:47201/.
-- A request runs in the background, and a function gets it once it is done, so the program never waits for the network.
-- A ws:// URL opens a WebSocket connection, here to the plugin's echo server at ws://127.0.0.1:47201/echo: then each typed line is a message, and bye closes it.

local ecs = require("ecs")
local web = require("web")
local net = require("net")
local draw = require("draw")
local websocket = require("websocket") -- the server side of WebSocket, in websocket.lua of the plugin's folder

local PORT = 47201
local SIZE = 16
local PAGES = { ["/"] = "Hello from OpenECS", ["/plain"] = "A plain page" }

local server = net.listen(PORT) -- nil if the port is taken
local clients = {}              -- the server's connections, until each closes
local log = { server and "Serving http://127.0.0.1:" .. PORT .. "/" or "Cannot serve on port " .. PORT }
local panels = {}               -- the open panels, drawn again when the log changes
local socket                    -- the WebSocket connection that typed lines go to, and its state

local function add(line)
  log[#log + 1] = line

  for panel in pairs(panels) do
    panel:redraw()
  end
end

-- the answer to what a client sent: a page for a GET of one, 404 for another path, and 400 for anything else
local function answer(received)
  local path = received:match("^GET (%S+)")
  local page = PAGES[path]
  local status = page and "200 OK" or path and "404 Not Found" or "400 Bad Request"
  page = page or status:sub(5)
  return ("HTTP/1.1 %s\r\nContent-Type: text/plain\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s"):format(status, #page, page)
end

-- what an echo client sent: each whole frame is answered, a text or bytes with the same message, and a close or bye with a close
local function echo(client)
  while true do
    local opcode, payload, rest = websocket.decode(client.pending)

    if not opcode then
      return
    end

    client.pending = rest

    if opcode == websocket.CLOSE or payload == "bye" then
      net.send(client.connection, websocket.encode(websocket.CLOSE, ""))
      net.close(client.connection)
      return
    elseif opcode == websocket.PING then
      net.send(client.connection, websocket.encode(websocket.PONG, payload))
    elseif opcode == websocket.TEXT or opcode == websocket.BINARY then
      net.send(client.connection, websocket.encode(opcode, payload))
    end
  end
end

-- the state of the WebSocket connection, and the messages that arrived; web keeps them until they are taken
local function poll()
  local status = web.socket.status(socket.handle)

  if status == 1 and not socket.open then
    socket.open = true
    add("Connected to " .. socket.url)
  end

  while true do
    local message, kind = web.socket.receive(socket.handle)

    if not kind then
      break
    end

    add(("Echo (%s): %s"):format(kind, message))
  end

  if status == -1 then
    add("Closed: " .. web.socket.error(socket.handle))
    web.socket.close(socket.handle)
    socket = nil
  end
end

-- every 50 ms: accept the server's clients and answer each, and look at the WebSocket connection
local timer = ecs.timer.start(0.05, true, function()
  local connection = server and net.accept(server)

  if connection then
    clients[#clients + 1] = { connection = connection, answered = false, pending = "" }
  end

  -- a client is kept until it closes, so what was sent to it leaves first
  for i = #clients, 1, -1 do
    local client = clients[i]
    local received = net.receive(client.connection, 4096)

    -- a request for a WebSocket on /echo turns the connection into one, whose frames go on in both directions; it starts with a greeting
    if received ~= "" and client.websocket then
      client.pending = client.pending .. received
      echo(client)
    elseif received ~= "" and not client.answered then
      local upgrade = received:match("^GET /echo ") and websocket.handshake(received)
      net.send(client.connection, upgrade or answer(received))
      client.answered, client.websocket = true, upgrade ~= nil

      if upgrade then
        net.send(client.connection, websocket.encode(websocket.TEXT, "Hello from the echo server"))
      end
    end

    if net.status(client.connection) == -1 then
      table.remove(clients, i)
    end
  end

  if socket then
    poll()
  end
end)

ecs.panel.registerType({
  name = "panel",
  title = "Fetch",

  create = function(panel)
    panels[panel] = true
    panel:setTextInput(true)
    return { panel = panel, line = "" }
  end,

  draw = function(fetch, surface)
    surface:fill(0, 0, surface.width, surface.height, "background")
    local _, height = draw.measure(draw.font("ui"), "Ag", SIZE)
    local lines = math.max(1, math.floor(surface.height / surface.scale / height) - 2)
    local first = math.max(1, #log - lines + 1)

    -- the last lines of the log, then the URL being typed
    for i = first, #log do
      draw.text(surface, draw.font("ui"), log[i], 12, 12 + (i - first) * height, SIZE, "text")
    end

    draw.text(surface, draw.font("ui"), "URL: " .. fetch.line, 12, 12 + lines * height, SIZE, "accent")
  end,

  event = function(fetch, event)
    if event.type == "text" then
      fetch.line = fetch.line .. event.text
    elseif event.type == "keyDown" and event.key == "Backspace" then
      fetch.line = fetch.line:sub(1, -2)
    elseif event.type == "keyDown" and event.key == "Return" and socket and not fetch.line:find("^%a+://") then
      -- a line that is not a URL is a message to the WebSocket connection; web sends it in the background, once the connection is open
      web.socket.send(socket.handle, fetch.line, true)
      fetch.line = ""
    elseif event.type == "keyDown" and event.key == "Return" and fetch.line:find("^wss?://") then
      -- web.socket.open starts a connection and gives its handle at once; its state and its messages are asked for, as with net
      if socket then
        web.socket.close(socket.handle)
      end

      local handle = web.socket.open(fetch.line)
      socket = handle and { handle = handle, url = fetch.line, open = false }
      add(handle and "Connecting to " .. fetch.line or "Cannot connect to " .. fetch.line)
      fetch.line = ""
    elseif event.type == "keyDown" and event.key == "Return" and fetch.line ~= "" then
      -- web.get starts a request and gives its handle at once; web.request takes a method, headers and a body too
      -- web keeps the function, and calls it on the main thread once the request is done, even if the handle is dropped
      local url = fetch.line

      local request = web.get(url, function(done)
        -- status is the HTTP status, or -1 if the request failed
        local status = web.status(done)

        if status > 0 then
          add(("%d %s: %s"):format(status, web.header(done, "Content-Type") or "?", web.body(done):match("[^\n]*")))
        else
          add("Failed: " .. web.error(done))
        end

        add("  for " .. url)
      end)

      if not request then
        add("Cannot request " .. url)
      end

      fetch.line = ""
    else
      return
    end

    fetch.panel:redraw()
  end,

  destroy = function(fetch)
    panels[fetch.panel] = nil
  end,
})

-- the log is the plugin's saved state, so the test can read it; the timer stops before the program exits
ecs.plugin.register({
  stateVersion = 1,
  saveState = function()
    return { log = log }
  end,
  restoreState = function() end,
  destroy = function()
    timer:stop()
  end,
})
