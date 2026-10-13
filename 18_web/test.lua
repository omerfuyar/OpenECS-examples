-- a typed URL is fetched in the background: the plugin's own pages, one it does not have, and HTTPS from a server that speaks plain HTTP

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
    test.match(waitFor(test, 3), { "Serving " .. base .. "/", "200 text/plain: Hello from OpenECS", "  for " .. base .. "/" })

    fetch(test, base .. "/missing")
    local log = waitFor(test, 5)
    test.match(log[4], "404 text/plain: Not Found", "the missing page")

    -- the server answers TLS's greeting with plain HTTP, so the request fails
    fetch(test, "https://127.0.0.1:47201/")
    log = waitFor(test, 7)
    test.match(log[6]:match("^Failed: ") ~= nil, true, "the HTTPS request")
  end,
}
