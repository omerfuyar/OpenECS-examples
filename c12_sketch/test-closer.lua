-- a panel that closes itself while it draws misuses ecs.layout.close: it faults and stays, and the canvas beside it draws on
return {
  preset = "preset-closer.lua",
  run = function(test)
    test.wait()
    test.match(test.panel(2), { type = "closer.panel" })
    assert(test.panel(2).fault and test.panel(2).fault:find("cannot open, move or close panels", 1, true), test.panel(2).fault)
    test.match(test.panel(1), { type = "sketch_lua.canvas" })
    assert(test.panel(1).fault == nil, test.panel(1).fault)

    -- a test fails on a misuse unless it takes it
    local misuses = test.misuses()
    assert(#misuses == 1 and misuses[1]:find("cannot open, move or close panels", 1, true), misuses[1])
  end,
}
