-- run waits for sort and gives its output; start runs the shell beside the tool, and a timer takes its output and its errors apart
return {
  preset = "preset.lua",
  run = function(test)
    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    -- waits until the program exited, at most a few seconds
    for _ = 1, 100 do
      if state().code then
        break
      end

      test.wait(0.05)
    end

    test.match(state(), { sorted = { "a", "b" }, lines = { "one", "two" }, errors = { "three" }, code = 0 }, "what the programs wrote")
  end,
}
