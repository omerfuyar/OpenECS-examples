-- the tally in Lua: its changes are records of the history plugin; the History panel lists them, a click on one goes to it, and an undo that
-- fails clears the history

local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset.lua",
  run = function(test)
    checks(test, 1, "tally")

    -- the History panel shows the history of the panel that had the focus, and a click on its first row, the state before every record,
    -- undoes them all
    local list = test.panel(2).state
    test.match(list.shown, "tally", "the History panel follows the focused panel")
    local box = test.rect(2)
    test.click(box.x + list.records.x + 20, box.y + list.records.y + 8)
    local tally = test.panel(1).state
    test.match({ tally.level, tally.history.position }, { 0.5, 0 }, "a click on the first row undoes every record")

    -- a change whose undo fails is reported, and the history is cleared, as its records may no longer match the panel's values
    local rect = tally.rects["break"]
    local panel = test.rect(1)
    test.click(panel.x + rect.x + rect.width / 2, panel.y + rect.y + rect.height / 2)
    test.key("Ctrl+Z")
    test.match(#test.panel(1).state.history.records, 0, "a failed undo clears the history")
  end,
}
