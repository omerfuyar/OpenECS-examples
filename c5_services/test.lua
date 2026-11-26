-- both panels add to the same counter in C, which tells both of each change, and tally.reset sets it back; bonus adds from C through Lua
return {
  preset = "preset.lua",
  run = function(test)
    local left, right = test.rect(1), test.rect(2)
    test.click(left.x + 20, left.y + 20)
    test.click(right.x + 20, right.y + 20)
    test.match(test.panel(2), { title = "Tally (2)" })
    test.match(test.panel(1), { title = "Tally (2)" }, "the kept callback")

    test.call("tally.reset")
    test.match(test.panel(2), { title = "Tally (0)" })
    test.click(left.x + 20, left.y + 20)
    test.match(test.panel(1), { title = "Tally (1)" })

    -- C calls tally's Lua function, which works, so no plugin reports an error
    test.call("bonus.give")
    test.match(test.panel(1), { title = "Tally (11)" })
    test.match(test.errors(), {}, "the errors")

    -- a test passes values to a function and gets its results, as a Lua plugin calls it: tally.addTo in Lua, which adds in C
    test.match({ test.call("tally.addTo", "clicks", 4) }, { 15 }, "tally.addTo's result")
    test.match(test.panel(1), { title = "Tally (15)" }, "the panels follow the counter")
    test.match(test.call("counter.get", "clicks"), 15, "counter.get's result")
  end,
}
