-- the checks of the tally, which the Lua plugin and the C plugin pass alike: each change is a record, Ctrl+Z and Ctrl+Y undo and redo the
-- focused panel's, a drag is one record, drop removes the tagged records, and the History panel goes to a record at a click; number is the
-- tally's panel's number, and name its history's

return function(test, number, name)
  local panel = test.rect(number)

  local function state()
    return test.panel(number).state
  end

  -- the middle of an element, or a place along it, in the window
  local function at(id, across)
    local rect = state().rects[id]
    local scale = test.scale and test.scale() or 1
    return panel.x + (rect.x + rect.width * (across or 0.5)) * scale, panel.y + (rect.y + rect.height / 2) * scale
  end

  local function labels()
    local found = {}

    for i, record in ipairs(state().history.records) do
      found[i] = record.label
    end

    return found
  end

  test.match(state().history.name, name, "the panel's history")

  -- each click is a record, and the keys undo and redo them in the focused panel
  for _ = 1, 3 do
    test.click(at("add"))
  end

  test.match({ state().count, labels(), state().history.position }, { 3, { "Add 1", "Add 1", "Add 1" }, 3 }, "three records")
  test.key("Ctrl+Z")
  test.key("Ctrl+Z")
  test.match({ state().count, state().history.position }, { 1, 1 }, "two undone")
  test.key("Ctrl+Y")
  test.match({ state().count, state().history.position }, { 2, 2 }, "one redone")
  test.key("Ctrl+Shift+Z")
  test.match({ state().count, state().history.position }, { 3, 3 }, "Ctrl+Shift+Z redoes too")

  -- a change after an undo drops the undone records
  test.key("Ctrl+Z")
  test.click(at("add"))
  test.match({ state().count, #labels(), state().history.position }, { 3, 3, 3 }, "a change drops what was undone")

  -- the slider's drag changes the level at each step, and the merge key makes them one record, which one undo takes back
  local x, y = at("level", 0.5)
  local right = at("level", 0.95)
  test.drag(x, y, right, y)
  test.match({ #labels(), labels()[4] }, { 4, "Level" }, "a drag is one record")
  test.match(state().level > 0.8, true, "the dragged level")
  test.key("Ctrl+Z")
  test.match(state().level, 0.5, "one undo takes the drag back")
  test.key("Ctrl+Y")

  -- drop removes the records tagged count, and keeps the level's
  test.click(at("forget"))
  test.match({ labels(), state().history.position }, { { "Level" }, 1 }, "the counts' records dropped")
end
