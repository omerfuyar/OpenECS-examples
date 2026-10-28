-- A worker's script. It runs on a thread of its own, in a Lua state of its own, so it shares no variables with the plugin's init.lua.
-- Its require("ecs") holds only log, plugin and worker: ecs.worker.receive waits for a message from the plugin, and ecs.worker.send sends one back.
-- A message is a copy of nil, a boolean, a number, a text, or a table of them.

local ecs = require("ecs")

-- the input that ecs.worker.start got is the script's ..., as a file's arguments are
local input = ...

-- whether a number is a prime, by trying the odd numbers up to its square root
local function isPrime(n)
  if n < 4 then
    return n > 1
  end

  if n % 2 == 0 then
    return false
  end

  for divisor = 3, math.floor(math.sqrt(n)), 2 do
    if n % divisor == 0 then
      return false
    end
  end

  return true
end

-- each message from the plugin is a chunk of numbers to count, until it says quit; what the script returns goes to the plugin's done
local chunks = 0

while true do
  local job = ecs.worker.receive()

  if job.quit then
    ecs.log.debug(("worker %d counted %d chunks"):format(input.number, chunks))
    return chunks
  end

  local primes = 0

  for n = job.from, job.to do
    if isPrime(n) then
      primes = primes + 1
    end
  end

  chunks = chunks + 1
  ecs.worker.send({ primes = primes })
end
