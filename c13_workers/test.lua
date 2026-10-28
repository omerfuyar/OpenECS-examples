-- four workers count the primes below 100000 at once, and Stop ends them

return {
  preset = "preset.lua",
  run = function(test)
    local panel = test.rect(1)

    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    local function at(id, across)
      local rect = state().rects[id]
      return panel.x + rect.x + rect.width * (across or 0.5), panel.y + rect.y + rect.height / 2
    end

    -- waits until the workers are done, at most a few seconds
    local function finish()
      for _ = 1, 200 do
        if not state().running then
          return
        end

        test.wait(0.05)
      end
    end

    -- the first of the three limits
    test.click(at("limit", 1 / 6))
    test.match(state().limit, "100 000", "the smallest limit")

    test.click(at("start"))
    test.match(state().running, true, "the workers count")
    finish()
    test.match(state(), { running = false, primes = 9592, chunks = 40 }, "the primes below 100000")

    -- the workers count each chunk once, all of them together
    local total = 0

    for _, chunks in pairs(state().done) do
      total = total + chunks
    end

    test.match(total, 40, "the chunks of all the workers")

    -- a second start counts again, from nothing
    test.click(at("start"))
    finish()
    test.match(state(), { primes = 9592, chunks = 40 }, "the second count")

    -- Stop ends the workers at once: no count comes after it
    test.click(at("limit", 5 / 6))
    test.click(at("start"))
    test.wait(0.1)
    test.click(at("stop"))
    local chunks = state().chunks
    test.wait(0.3)
    test.match(state(), { running = false, chunks = chunks }, "the stopped count")
  end,
}
