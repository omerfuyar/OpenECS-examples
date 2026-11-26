-- the tool's default history: Ctrl+Z and Ctrl+Y act on it in a panel without one of its own, a panel's own history wins over it, and the
-- History panel follows the focus to it; nil and closing it take it away. tally_c makes its history the default from C, and the note's
-- buttons call useDefault from Lua

return {
  preset = "preset_default.lua",
  run = function(test)
    local function add(number)
      local box, rect = test.rect(number), test.panel(number).state.rects.add
      test.click(box.x + rect.x + rect.width / 2, box.y + rect.y + rect.height / 2)
    end

    -- a click on the note, below its buttons, or on one of them
    local function note(button)
      local box = test.rect(3)
      local rect = button and test.panel(3).state.rects[button]

      if rect then
        test.click(box.x + rect.x + rect.width / 2, box.y + rect.y + rect.height / 2)
      else
        test.click(box.x + box.width / 2, box.y + box.height - 8)
      end
    end

    local function counts()
      return { test.panel(1).state.count, test.panel(2).state.count }
    end

    -- the C tally made its history the default: the keys act on it in the note, which keeps none, and the History panel follows to it
    add(2)
    add(1)
    note()
    test.match(test.panel(4).state.shown, "tally_c", "the History panel follows the focus to the default history")
    test.key("Ctrl+Z")
    test.match(counts(), { 1, 0 }, "Ctrl+Z in a panel without a history undoes the default one")
    test.key("Ctrl+Y")
    test.match(counts(), { 1, 1 }, "Ctrl+Y redoes it")

    -- each row shows its record's tags after its label
    local list = test.panel(4).state
    test.match({ list.first, list.rows }, { 1, { "Before every change", "Add 1    count" } }, "a row shows its record's tags")

    -- a panel's own history wins over the default one
    add(1)
    test.key("Ctrl+Z")
    test.match(counts(), { 1, 1 }, "Ctrl+Z in a tally undoes its own history")
    test.key("Ctrl+Z")
    test.match(counts(), { 0, 1 }, "and only its own")

    -- a Lua plugin names the default as C does, and nil takes it away
    note("tally")
    test.match(test.panel(4).state.shown, "tally", "the History panel follows to the new default")
    test.key("Ctrl+Y")
    test.match(counts(), { 1, 1 }, "Ctrl+Y in the note redoes the new default")
    note("none")
    test.key("Ctrl+Z")
    test.match(counts(), { 1, 1 }, "without a default, Ctrl+Z in the note does nothing")

    -- closing the default history takes it away too
    local scratch = test.call("history.open", "scratch")
    local value = 0
    test.call("history.change", scratch, "Set", "", 0, 1, function(new) value = new end, nil)
    test.call("history.useDefault", scratch)
    test.key("Ctrl+Z")
    test.match(value, 0, "Ctrl+Z in the note undoes the scratch history")
    test.key("Ctrl+Y")
    test.call("history.close", scratch)
    test.key("Ctrl+Z")
    test.match({ value, counts() }, { 1, { 1, 1 } }, "after the default history closes, Ctrl+Z in the note does nothing")
  end,
}
