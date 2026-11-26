-- two panels with their own histories: Ctrl+Z undoes only the focused panel's, and the History panel follows the focus

return {
  preset = "preset_both.lua",
  run = function(test)
    local function add(number)
      local box, rect = test.rect(number), test.panel(number).state.rects.add
      test.click(box.x + rect.x + rect.width / 2, box.y + rect.y + rect.height / 2)
    end

    add(1)
    test.match(test.panel(3).state.shown, "tally", "the History panel shows the Lua tally's history")
    add(2)
    add(2)
    test.match(test.panel(3).state.shown, "tally_c", "the History panel follows the focus to the C tally")
    test.key("Ctrl+Z")
    test.match({ test.panel(1).state.count, test.panel(2).state.count }, { 1, 1 }, "Ctrl+Z undoes only the focused panel's history")
    add(1)
    test.key("Ctrl+Z")
    test.key("Ctrl+Z")
    test.match({ test.panel(1).state.count, test.panel(2).state.count }, { 0, 1 }, "and in the other panel, only its own")
  end,
}
