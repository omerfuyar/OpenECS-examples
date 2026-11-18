-- the listener hears the ticker's ticks, also with a subscription it renews at each, counts its own panel opening, and hears its own event,
-- which carries a handle and bytes
return {
  preset = "preset.lua",
  run = function(test)
    test.wait(0.5) -- lets the program run, so the timer ticks

    local ticks, panels, greeted = test.panel(1).title:match("^Ticks (%d+), panels (%d+)(.*)$")
    assert(tonumber(ticks) >= 2, "ticks heard: " .. tostring(ticks))
    test.match(panels, "1", "panels opened")
    test.match(greeted, ", greeted", "the event with a handle and bytes")

    -- the subscription that renews itself at each tick heard each tick once
    local state = test.panel(1).state
    test.match(state.renewed, state.ticks, "the ticks that the renewed subscription heard")
  end,
}
