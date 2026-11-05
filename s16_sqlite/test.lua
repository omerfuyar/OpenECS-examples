-- the query gives the rows the panel added and updated, sorted, and Return adds a row
return {
  preset = "preset.lua",
  run = function(test)
    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    test.match(state(), {
      rows = { { name = "apple", count = 7 }, { name = "banana", count = 5 }, { name = "orange", count = 2 } },
      total = 14,
      changed = 1,
    }, "the table after the inserts and the update")

    test.key("Return")
    test.match(state(), { total = 18, rows = { { name = "apple" }, { name = "banana" }, { name = "cherry", count = 4 }, { name = "orange" } } }, "after Return")
  end,
}
