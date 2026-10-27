-- both panels add to the same counter in C, which tells both of each change, and tally.reset sets it back
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
  end,
}
