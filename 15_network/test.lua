-- a typed line goes to the server, which sends it back in capitals; a line that starts with /udp goes and comes back in datagrams

-- waits until the log ends with a line, and gives the log
local function waitFor(test, line)
  local log

  for _ = 1, 100 do
    test.wait(0.05)
    log = test.session().pluginState.echo.state.log

    if log[#log] == line then
      break
    end
  end

  return log
end

return {
  preset = "preset.lua",
  run = function(test)
    -- the connection is made in the background, while the test waits
    test.wait(0.5)
    test.text("hello")
    test.key("Return")
    test.match(waitFor(test, "< HELLO"), { "Listening on port 47200", "> hello", "< HELLO" })

    test.text("/udp hi")
    test.key("Return")
    test.match(waitFor(test, "< udp HI"), { "Listening on port 47200", "> hello", "< HELLO", "> udp hi", "< udp HI" })

    -- the TLS connection to the plain server fails its handshake
    test.match(test.session().pluginState.echo.state.tls, -1, "the TLS connection")
  end,
}
