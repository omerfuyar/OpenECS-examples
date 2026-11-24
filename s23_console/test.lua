-- the console keeps the entries that a plugin adds, and stacks a repeated one; a click on the place that an entry names runs
-- the command of console.editor; a click chooses an entry, a double click goes to what it is about, and Ctrl+C and its menu copy
-- it; the levels' toggles and the search filter the entries, a run clears them while Clear on run is on, and Clear empties the
-- console
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
    -- console's folder; touch is a program of Linux, so the click is checked there. The program may take seconds to start on a slow machine
    if package.config:sub(1, 1) == "/" then
      test.click(log.x + 97, log.y + 121)
      local found = false
      for _ = 1, 400 do
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

    -- a click on an entry chooses it, and Ctrl+C copies its text, with how many times it stacked
    test.click(log.x + 400, log.y + 141)
    test.match(test.panel(logId).state, { chosen = "main.lua:3: attempt to call a nil value" }, "a click chooses the entry")
    test.key("Ctrl+C")
    test.match(state(), { clipboard = "main.lua:3: attempt to call a nil value (×2)" }, "Ctrl+C copies the chosen entry")
    test.wait(0.5)

    -- a double click goes to what an entry is about: the file and line it names, or else its first link, as the info's
    -- entry names neither, and the error's runs console.editor, as a click on its place does
    test.click(log.x + 400, log.y + 78)
    test.click(log.x + 400, log.y + 78)
    test.match(test.panel(logId).state, { chosen = "Running main.lua\nstarted" }, "a double click on an entry without a place chooses it")
    test.wait(0.5)
    if package.config:sub(1, 1) == "/" then
      test.click(log.x + 400, log.y + 141)
      test.click(log.x + 400, log.y + 141)
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
      assert(found, "a double click on the error ran the command of console.editor")
      os.remove(mark)
      test.wait(0.5)
    end

    -- a right click opens the entry's menu, whose Copy copies it
    test.call("runner.forget")
    test.click(log.x + 400, log.y + 78, 3)
    local menu = test.popup(1)
    assert(menu, "a right click opens a menu")
    test.click(menu.x + 20, menu.y + menu.height * 3 / 4)
    test.match(state(), { clipboard = "Running main.lua\nstarted" }, "the menu's Copy copies the entry")

    -- the Errors toggle hides the errors' entries, which the panel's state keeps, and shows them again
    test.click(log.x + 189, log.y + 21)
    test.match(test.panel(logId).state, { hidden = { error = true } }, "the toggle hides the errors")
    test.click(log.x + 189, log.y + 21)
    test.match(test.panel(logId).state, { hidden = {} }, "and shows them again")

    -- the search, beside the toggles, shows only the entries that hold its text
    test.click(log.x + 340, log.y + 21)
    test.text("NIL")
    test.wait()
    test.match(test.panel(logId).state, { shown = 1 }, "the search shows the error alone")
    test.key("Ctrl+A")
    test.key("Backspace")
    test.wait()
    test.match(test.panel(logId).state, { shown = 2 }, "and every entry when it is empty")

    -- another run clears the console first; with Clear on run off, it adds to it
    test.click(button.x + 30, button.y + 24)
    test.match(state(), { entries = 2 }, "a run clears the console")
    test.click(log.x + log.width - 161, log.y + 21)
    test.click(button.x + 30, button.y + 24)
    test.match(state(), { entries = 4 }, "without Clear on run, a run adds to the console")
    test.click(log.x + log.width - 161, log.y + 21)

    test.click(log.x + log.width - 34, log.y + 21)
    test.match(state(), { entries = 0 }, "Clear empties the console")

    -- a long console builds only the entries in view, and follows the last; Up chooses the entries above, which were not built, and
    -- scrolls to each
    test.call("runner.many")
    test.wait(0.2)
    test.match(test.panel(logId).state.shown, 500, "the long console's entries")
    assert(test.panel(logId).state.built < 100, "a long console builds only the entries in view")
    test.click(log.x + 400, log.y + log.height - 20)
    test.match(test.panel(logId).state.chosen, "entry 500", "the long console follows its last entry")
    for _ = 1, 30 do
      test.key("Up")
    end
    test.match(test.panel(logId).state.chosen, "entry 470", "Up chooses entries that were not built")
    assert(test.panel(logId).state.built < 100, "and the console still builds only the entries in view")
  end,
}
