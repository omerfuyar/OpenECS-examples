-- disabling the primes plugin while its workers count stops them: its panel waits as a placeholder, and enabling the plugin again
-- gives the panel back, which counts again from the start

return {
  preset = "preset-switch.lua",
  run = function(test)
    local panel = test.rect(1)

    local function state()
      return test.panel(1).state
    end

    local function at(id, across)
      local rect = state().rects[id]
      return panel.x + rect.x + rect.width * (across or 0.5), panel.y + rect.y + rect.height / 2
    end

    -- the largest limit, so the workers still count when the plugin goes
    test.click(at("limit", 5 / 6))
    test.click(at("start"))
    test.wait(0.05)
    test.match(state().running, true, "the workers count")

    test.call("switch.disable")
    test.wait(0.3)
    test.match(test.panel(1).type, "primes.panel", "the panel's type, kept")
    assert(test.panel(1).fault, "the panel waits as a placeholder")

    test.call("switch.enable")
    test.wait(0.1)
    assert(test.panel(1).fault == nil, test.panel(1).fault)
    test.click(at("limit", 1 / 6))
    test.click(at("start"))

    for _ = 1, 200 do
      if not state().running then
        break
      end

      test.wait(0.05)
    end

    test.match(state(), { running = false, primes = 9592, chunks = 40 }, "the primes below 100000, after the plugin came back")
  end,
}
