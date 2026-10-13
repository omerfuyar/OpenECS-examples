-- Fetches each typed URL with the web standard plugin, and shows the answer's status, type and first line.
-- So the example works without the internet, the plugin also serves two pages on this computer with net, at http://127.0.0.1:47201/.
-- A request runs in the background, and a function gets it once it is done, so the program never waits for the network.

local ecs = require("ecs")
local web = require("web")
local net = require("net")
local draw = require("draw")

local PORT = 47201
local SIZE = 16
local PAGES = { ["/"] = "Hello from OpenECS", ["/plain"] = "A plain page" }

local server = net.listen(PORT) -- nil if the port is taken
local clients = {}              -- the server's connections, until each closes
local log = { server and "Serving http://127.0.0.1:" .. PORT .. "/" or "Cannot serve on port " .. PORT }
local panels = {}               -- the open panels, drawn again when the log changes

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

-- every 50 ms: accept the server's clients and answer each once
local timer = ecs.timer.start(0.05, true, function()
  local connection = server and net.accept(server)

  if connection then
    clients[#clients + 1] = { connection = connection, answered = false }
  end

  -- a client is kept until it closes, so what was sent to it leaves first
  for i = #clients, 1, -1 do
    local client = clients[i]
    local received = net.receive(client.connection, 4096)

    if received ~= "" and not client.answered then
      net.send(client.connection, answer(received))
      client.answered = true
    end

    if net.status(client.connection) == -1 then
      table.remove(clients, i)
    end
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
