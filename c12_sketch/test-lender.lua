-- a brush freed while Lua holds its handle: the handle raises an error, and the canvas that uses the brush draws with it still
return {
  preset = "preset-lender.lua",
  run = function(test)
    test.call("lender.lend")

    -- using the freed handle is a misuse, which disables the lender; the test takes it, so it does not fail on it
    local freed = test.session().pluginState.lender.state.freed
    local misuses = test.misuses()
    assert(freed and freed:find("the object of this handle is gone", 1, true), freed)
    test.match(#misuses, 1, "the misuse of the freed handle")

    local rect = test.rect(1)
    test.drag(rect.x + 40, rect.y + 60, rect.x + 240, rect.y + 60)
    test.match(test.pixel(rect.x + 140, rect.y + 60), "#5E81AC", "the canvas draws with the freed brush")
  end,
}
