-- the console keeps the entries that a plugin adds, and stacks a repeated one; a click on the place that an entry names runs
-- the command of console.editor; the levels' toggles filter the entries, a run clears them while Clear on run is on, and Clear
-- empties the console
return {
  preset = "preset.lua",
  run = function(test)
    local runner, log, logId
    for _, panel in ipairs(test.panels()) do
      if panel.type == "runner.panel" then
        runner = panel.id
      elseif panel.type == "console.log" then
        log, logId = test.rect(panel.id), panel.id
      end
    end
    local function state()
      return test.panel(runner).state
    end
    local mark = state().folder .. "main.lua.3"
    os.remove(mark)

    -- a run adds two entries, the second added twice, which stacks
    local button = test.rect(runner)
    test.click(button.x + 30, button.y + 24)
    test.match(state(), { entries = 2, count = 2 }, "Run adds two entries, and the repeated one stacks")

    -- the error's entry names main.lua at line 3, above its text: a click runs console.editor with the file's path in the
    -- console's folder; touch is a program of Linux, so the click is checked there
    if package.config:sub(1, 1) == "/" then
      test.click(log.x + 97, log.y + 121)
      local found = false
      for _ = 1, 100 do
        local file = io.open(mark, "rb")
        if file then
          file:close()
          found = true
          break
        end
        test.wait(0.05)
      end
      assert(found, "the click ran the command of console.editor")
      os.remove(mark)
    end

    test.click(log.x + 150, log.y + 121)
    test.match(state(), { shown = 1 }, "a click on the error's own link calls its function")

    -- the Errors toggle hides the errors' entries, which the panel's state keeps, and shows them again
    test.click(log.x + 189, log.y + 21)
    test.match(test.panel(logId).state, { hidden = { error = true } }, "the toggle hides the errors")
    test.click(log.x + 189, log.y + 21)
    test.match(test.panel(logId).state, { hidden = {} }, "and shows them again")

    -- another run clears the console first; with Clear on run off, it adds to it
    test.click(button.x + 30, button.y + 24)
    test.match(state(), { entries = 2 }, "a run clears the console")
    test.click(log.x + log.width - 161, log.y + 21)
    test.click(button.x + 30, button.y + 24)
    test.match(state(), { entries = 4 }, "without Clear on run, a run adds to the console")
    test.click(log.x + log.width - 161, log.y + 21)

    test.click(log.x + log.width - 34, log.y + 21)
    test.match(state(), { entries = 0 }, "Clear empties the console")
  end,
}
