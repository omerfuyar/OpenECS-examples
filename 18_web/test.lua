-- a typed URL is fetched in the background: the plugin's own pages, one it does not have, and HTTPS from a server that speaks plain HTTP
-- a ws:// URL opens a WebSocket connection to the plugin's echo server, which greets, echoes each typed line, and closes after bye

-- waits until the log has a number of lines, and gives the log
local function waitFor(test, count)
  local log

  for _ = 1, 100 do
    test.wait(0.05)
    log = test.session().pluginState.fetch.state.log

    if #log >= count then
      break
    end
  end

  return log
end

local function fetch(test, url)
  test.text(url)
  test.key("Return")
end

return {
  preset = "preset.lua",
  run = function(test)
    local base = "http://127.0.0.1:47201"
    fetch(test, base .. "/")

    -- the plugin drops the request's handle; web keeps the request until its function has it
    collectgarbage()
    test.match(waitFor(test, 3), { "Serving " .. base .. "/", "200 text/plain: Hello from OpenECS", "  for " .. base .. "/" })

    fetch(test, base .. "/missing")
    local log = waitFor(test, 5)
    test.match(log[4], "404 text/plain: Not Found", "the missing page")

    -- the server answers TLS's greeting with plain HTTP, so the request fails in its handshake; web's mbedTLS names SSL in the error
    fetch(test, "https://127.0.0.1:47201/")
    log = waitFor(test, 7)
    test.match(log[6]:match("^Failed: .*SSL") ~= nil, true, "the HTTPS request: " .. tostring(log[6]))

    -- a message typed before the connection is open waits, and goes once it is
    fetch(test, "ws://127.0.0.1:47201/echo")
    fetch(test, "early")
    log = waitFor(test, 11)
    test.match({ log[8], log[9], log[10], log[11] }, { "Connecting to ws://127.0.0.1:47201/echo", "Connected to ws://127.0.0.1:47201/echo", "Echo (text): Hello from the echo server", "Echo (text): early" }, "the connection")

    -- a long message comes back in many frames of the network, as one message
    local long = ("0123456789"):rep(1000)
    fetch(test, long)
    log = waitFor(test, 12)
    test.match(log[12], "Echo (text): " .. long, "the long message")

    fetch(test, "bye")
    log = waitFor(test, 13)
    test.match(log[13], "Closed: The server closed the connection", "the closed connection")
  end,
}
