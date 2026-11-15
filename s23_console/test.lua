-- the console keeps the lines that a plugin adds; a click on a line that names a file runs the command of console.editor,
-- and Clear empties it
return {
  preset = "preset.lua",
  run = function(test)
    local runner, log
    for _, panel in ipairs(test.panels()) do
      if panel.type == "runner.panel" then
        runner = panel.id
      elseif panel.type == "console.log" then
        log = test.rect(panel.id)
      end
    end
    local function state()
      return test.panel(runner).state
    end
    local mark = state().folder .. "main.lua.3"
    os.remove(mark)

    -- each line of an added text is a line of the console
    local button = test.rect(runner)
    test.click(button.x + 30, button.y + 24)
    test.match(state(), { lines = 3 }, "Run adds three lines")

    -- the third line names main.lua at line 3: a click runs console.editor with the file's path in the console's folder;
    -- touch is a program of Linux, so the click is checked there
    if package.config:sub(1, 1) == "/" then
      test.click(log.x + 60, log.y + 89)
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

    test.click(log.x + log.width - 34, log.y + 21)
    test.match(state(), { lines = 0 }, "Clear empties the console")
  end,
}
