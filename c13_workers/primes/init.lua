-- Counting primes on four threads at once. A worker is a Lua script that runs on a thread of its own, in a Lua state of its own (OpenECS DESIGN 3.4).
-- The panel splits the numbers into chunks and gives each worker one. A worker sends its count back and gets the next chunk, so a faster worker counts more.
-- Plugin code always runs on the main thread, and the workers never block it: the panel's clock keeps going while they count, and Stop ends them at once.

local ecs = require("ecs")
local ui = require("ui")

-- ui's own styles, which its standard views use too
local STYLES = ui.styles()

local WORKERS = 4
local CHUNKS = 40 -- the numbers are split into this many chunks
local LIMITS = { "100 000", "1 000 000", "10 000 000" }
local BAR = 240 -- the width of a worker's bar, in layout units

-- the elements the test clicks, by id; their rectangles are saved, so the test finds them
local IDS = { "limit", "start", "stop" }

-- stops the workers and the clock; a stopped worker's message and done functions are not called again
local function stop(counter)
  for _, worker in ipairs(counter.workers) do
    worker:stop()
  end

  if counter.clock then
    counter.clock:stop()
  end

  counter.workers, counter.clock, counter.running = {}, nil, false
end

local function start(counter)
  stop(counter)

  local limit = tonumber((LIMITS[counter.limit]:gsub(" ", "")))
  local size = math.floor((limit - 2) / CHUNKS) + 1
  local next, finished = 1, 0
  counter.primes, counter.chunks, counter.seconds, counter.done, counter.running = 0, 0, 0, {}, true

  -- the clock counts tenths of a second; a repeating timer skips the calls it missed, so it would fall behind if the main thread were busy
  counter.clock = ecs.timer.start(0.1, true, function()
    counter.seconds += 0.1
    counter.panel:redraw()
  end)

  -- gives a worker the next chunk of the numbers below the limit, or tells it to quit when none is left
  local function give(worker)
    if next > CHUNKS then
      worker:send({ quit = true })
      return
    end

    worker:send({ from = (next - 1) * size + 1, to = math.min(next * size, limit - 1) })
    next += 1
  end

  for i = 1, WORKERS do
    -- file is in the plugin's folder; input is copied to the worker, as the messages are
    local worker
    worker = assert(ecs.worker.start({
      file = "count.lua",
      input = { number = i },

      -- each message the worker sends comes here, on the main thread: a chunk's count
      message = function(message)
        counter.primes += message.primes
        counter.chunks += 1
        counter.done[i] = (counter.done[i] or 0) + 1
        give(worker)
        counter.panel:redraw()
      end,

      -- the script ended: ok is true and chunks is what it returned, or ok is false and chunks is the error
      done = function(ok, chunks)
        ecs.log.debug(("worker %d ended: %s, %s"):format(i, ok, chunks))
        finished += 1

        if finished == WORKERS then
          stop(counter)
          counter.panel:redraw()
        end
      end,
    }))

    counter.workers[i] = worker

    -- a function, a handle or a struct cannot be encoded as a message, so sending one is an error; a struct's fields go as a table
    counter.refused = not pcall(worker.send, worker, print)
    give(worker)
  end
end

-- each panel's state is an object of Primes, whose functions are methods
local Primes = {}
Primes.__index = Primes

function Primes.create(panel)
  return setmetatable({ panel = panel, limit = 2, running = false, primes = 0, chunks = 0, seconds = 0, done = {}, workers = {} }, Primes)
end

function Primes:view(surface)
  self.scale = surface.scale
  -- a bar shows a share of the chunks: the first one all the workers' together, and the others each worker's own
  local function bar(label, done)
    return ui.row({ gap = 8, align = "center" }, {
      ui.text(label, { width = 70 }),
      ui.row({ width = BAR, height = 12, background = "tabRow" }, {
        ui.row({ width = BAR * done / CHUNKS, height = 12, background = "accent" }),
      }),
      ui.text(("%d chunks"):format(done), { style = STYLES.note }),
    })
  end

  local bars = { bar("All", self.chunks) }

  for i = 1, WORKERS do
    bars[i + 1] = bar(("Worker %d"):format(i), self.done[i] or 0)
  end

  local status = self.running and ("Counting: %d of %d chunks, %.1f s"):format(self.chunks, CHUNKS, self.seconds)
      or self.chunks == CHUNKS and ("%d primes below %s, in about %.1f s"):format(self.primes, LIMITS[self.limit], self.seconds)
      or "Press Start to count the primes."

  return ui.column({ style = STYLES.view }, {
    ui.text("Four workers count the primes, each on a thread of its own. Drag the panel or open its menu while they count: it stays free.", { wrap = true }),
    ui.row({ gap = 8, align = "center" }, {
      ui.text("Below"),
      ui.selector(self.limit, LIMITS, { id = "limit", onSelect = function(limit) self.limit = limit end }),
    }),
    ui.row({ gap = 8 }, {
      ui.button("Start", { id = "start", onClick = function() start(self) end }),
      ui.button("Stop", { id = "stop", onClick = function() stop(self) end }),
    }),
    ui.column({ gap = 6 }, bars),
    ui.text(status, { size = 16 }),
  })
end

function Primes:destroy()
  stop(self)
end

-- the rectangles of the elements in the last show, in the panel's surface pixels; ui.rect gives nil for an element that is not shown, such as one
-- on another tab
local function rects(panel, scale)
  local found = {}

  for _, id in ipairs(IDS) do
    local rect = ui.rect(panel, id)
    found[id] = rect and { x = rect.x * scale, y = rect.y * scale, width = rect.width * scale, height = rect.height * scale }
  end

  return found
end

-- the counts are saved, so the test can read them
function Primes:saveState()
  return { limit = LIMITS[self.limit], running = self.running, primes = self.primes, chunks = self.chunks, done = self.done, rects = rects(self.panel, self.scale), refused = self.refused }
end

ecs.panel.registerType(ui.panelType({
  name = "panel",
  title = "Workers",

  create = Primes.create,

  view = Primes.view,

  destroy = Primes.destroy,

  saveState = Primes.saveState,
}))
