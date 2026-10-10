-- a typed line goes to the server, which sends it back in capitals
return {
  preset = "preset.lua",
  run = function(test)
    -- the connection is made in the background, while the test waits
    test.wait(0.5)
    test.text("hello")
    test.key("Return")

    local log

    for _ = 1, 100 do
      test.wait(0.05)
      log = test.session().pluginState.echo.state.log

      if log[#log] == "< HELLO" then
        break
      end
    end

    test.match(log, { "Listening on port 47200", "> hello", "< HELLO" })
  end,
}
