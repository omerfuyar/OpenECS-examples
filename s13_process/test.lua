-- run waits for sort and gives its output, and gives a program a variable; start runs the shell beside the tool, and a timer takes its output and its errors apart;
-- a started sort takes its input, a started program is killed, and a missing one cannot start
return {
  preset = "preset.lua",
  run = function(test)
    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    -- waits until the program exited, at most a few seconds
    for _ = 1, 100 do
      if state().code and state().sortCode and state().killed then
        break
      end

      test.wait(0.05)
    end

    test.match(state(), { sorted = { "a", "b" }, greeting = { "hello" }, counted = 200000, lines = { "one", "two" }, errors = { "three" }, code = 0 }, "what the programs wrote")

    -- a started program's input, written and closed; a killed program; and one that cannot start
    test.match(state(), { sortedLater = { "c", "d" }, sortCode = 0, killed = true, missing = true }, "input, kill and a missing program")
  end,
}
