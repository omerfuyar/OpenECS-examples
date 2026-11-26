-- the listener hears the ticker's ticks, also with a subscription it renews at each, counts its own panel opening, and hears its own event,
-- which carries a handle and bytes, and the event after it, whose handler frees a handle; it and a C plugin hear the log through ecs.logged;
-- the C panel draws again at each heard_c.poked, which its type's redrawOn names
return {
  preset = "preset.lua",
  run = function(test)
    test.wait(0.5) -- lets the program run, so the timer ticks

    local ticks, panels, greeted = test.panel(1).title:match("^Ticks (%d+), panels (%d+)(.*)$")
    assert(tonumber(ticks) >= 2, "ticks heard: " .. tostring(ticks))
    test.match(panels, "2", "panels opened, the listener and the C panel")
    test.match(greeted, ", greeted", "the event with a handle and bytes")

    -- the subscription that renews itself at each tick heard each tick once
    local state = test.panel(1).state
    test.match(state.renewed, state.ticks, "the ticks that the renewed subscription heard")

    -- a handler that collects a handle after an earlier event was delivered leaves that event's freed value alone
    test.match(state.noted, 1, "the event after the one with a handle")

    -- the log's lines come as ecs.logged, to Lua and to C alike, and a handler that logs does not hear its own line
    test.match(state.logged, 1, "the listener's warning, heard in Lua")
    test.match(state.echoed, 0, "the line that the Lua handler logged")
    test.match(test.panel(2).state, { heard = 1, echoed = 0 }, "the warning heard in C, and the line its handler logged")

    -- an idle panel draws nothing more; each emission of an event of redrawOn draws it again, also of one declared after the type
    local drawn = test.panel(2).state.drawn
    test.wait(0.2)
    test.match(test.panel(2).state.drawn, drawn, "the draws of an idle panel")
    test.call("heard_c.poke")
    test.wait()
    test.match(test.panel(2).state.drawn, drawn + 1, "the draws after heard_c.poked")
    test.match(test.errors(), {}, "the errors, with a name in redrawOn that nothing declares")

    -- a reloaded plugin registers its type again, and declares heard_c.poked again after it: the event still draws its panels
    local rect = test.rect(2)
    test.click(rect.x + 20, rect.y + 20)
    test.call("ecs.panel.reloadPlugin")
    test.wait()
    test.match(test.panel(2), { type = "heard_c.panel", fault = nil }, "the C panel after its plugin reloaded")
    drawn = test.panel(2).state.drawn
    test.call("heard_c.poke")
    test.wait()
    test.match(test.panel(2).state.drawn, drawn + 1, "the draws after heard_c.poked, once the plugin reloaded")
  end,
}
