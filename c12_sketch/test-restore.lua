-- a handle parameter that may be nil, handle<name>?, takes nil, which C gets as nullptr: the canvas draws with the settings' brush again
-- after a blue one; nil for a handle that may not be nil is an error at the call, which names the function
return {
  preset = "preset-lender.lua",
  run = function(test)
    local rect = test.rect(1)
    test.call("lender.paint")
    test.drag(rect.x + 40, rect.y + 60, rect.x + 240, rect.y + 60)
    test.match(test.pixel(rect.x + 140, rect.y + 60), "#5E81AC", "the canvas draws with the blue brush")

    test.call("lender.restore")
    test.match(#test.misuses(), 0, "nil for the brush that may be nil is no misuse")
    test.drag(rect.x + 40, rect.y + 120, rect.x + 240, rect.y + 120)
    test.match(test.pixel(rect.x + 140, rect.y + 120), "#ECEFF4", "the canvas draws with the settings' white brush again")

    test.call("lender.refuse")
    local refused = test.session().pluginState.lender.state.refused
    assert(refused and refused:find("'sketch_c.freeBrush'", 1, true), refused)
    test.misuses()
  end,
}
