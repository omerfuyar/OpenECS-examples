-- A panel that runs programs with the process standard plugin, and shows what they wrote.
-- process.run waits for a program and gives its output, so it suits short programs. process.start does not wait: the program runs beside
-- the tool, and the plugin takes its output and errors when it wants, here from a timer, so the tool never waits for it.

local ecs = require("ecs")
local draw = require("draw")
local process = require("process")

-- the programs here are the system's shell, sh on Linux and cmd on Windows, which runs a command line
local WINDOWS = package.config:sub(1, 1) == "\\"

local function shell(line)
  return WINDOWS and { "cmd", "/c", line } or { "sh", "-c", line }
end

-- the lines of a text, without the spaces and line breaks around them
local function lines(text, into)
  for line in text:gmatch("[^\r\n]+") do
    into[#into + 1] = line:match("^%s*(.-)%s*$")
  end

  return into
end

-- each panel's state is an object of Runner, whose functions are methods
local Runner = {}
Runner.__index = Runner

-- takes what the sorter wrote, and whether the sorter and the stopped program exited
function Runner:pollOthers()
  lines(self.sorter:read(), self.sortedLater)
  local sorted, sortCode = self.sorter:exited()

  if sorted and self.sortCode == nil then
    lines(self.sorter:read(), self.sortedLater)
    self.sortCode = sortCode
  end

  self.killed = self.killed or self.sleeper:exited()
end

-- takes what the started programs wrote since the last time; once they exited, the timer stops
function Runner:poll()
  self:pollOthers()
  lines(self.program:read(), self.lines)
  lines(self.program:readErrors(), self.errors)
  local exited, code = self.program:exited()

  -- what it wrote before it exited may still wait, so it is read once more
  if exited then
    lines(self.program:read(), self.lines)
    lines(self.program:readErrors(), self.errors)
    self.code = code
  end

  if self.code and self.sortCode and self.killed then
    self.timer:stop()
  end

  self.panel:redraw()
end

function Runner.create(panel)
  local state = setmetatable({ panel = panel, lines = {}, errors = {} }, Runner)

  -- run gives a program its input, which sort reads to the end, and waits for its output
  state.sorted = lines(process.run(shell("sort"), "", "b\na\n"), {})

  -- a large input goes while the output is read, as the program's input pipe takes only part of it at a time
  state.counted = #lines(process.run(shell("sort"), "", ("line\n"):rep(200000)), {})

  -- start gives a handle of the program; its methods read, write, kill it and tell whether it exited
  local program, problem = process.start(shell("echo one && echo two && echo three 1>&2"), "")
  state.program = assert(program, problem)

  -- a started program takes input too: write sends it, and closeInput ends it, so sort, which reads to the end, sorts and exits
  state.sorter = assert(process.start(shell("sort"), ""))
  state.sortedLater = {}
  state.sorter:write("d\nc\n")
  state.sorter:closeInput()

  -- kill stops a program that would run on; with force, at once
  -- the program runs alone, without a shell, so killing it leaves nothing behind
  state.sleeper = assert(process.start(WINDOWS and { "ping", "-n", "30", "127.0.0.1" } or { "sleep", "30" }, ""))
  state.sleeper:kill(true)

  -- a program that cannot start gives nothing and why
  local missing, why = process.start({ "openecs-no-such-program" }, "")
  state.missing = missing == nil and type(why) == "string" and why ~= ""

  state.timer = ecs.timer.start(0.05, true, function()
    state:poll()
  end)

  return state
end

-- a program whose handle is gone is killed, so none is left behind
function Runner:destroy()
  self.timer:stop()
end

function Runner:draw(surface)
  surface:fill(0, 0, surface.width, surface.height, "background")
  local font, y = draw.font("ui"), 16

  local function show(text, color)
    draw.text(surface, font, text, 16, y, 18, color)
    y += 26
  end

  show("sort gave: " .. table.concat(self.sorted, ", "), "text")

  for _, line in ipairs(self.lines) do
    show(line, "text")
  end

  for _, line in ipairs(self.errors) do
    show(line, "accent")
  end

  show(self.code and ("exited with " .. self.code) or "running", "textDim")
end

-- what the test reads
function Runner:saveState()
  return { sorted = self.sorted, counted = self.counted, lines = self.lines, errors = self.errors, code = self.code, sortedLater = self.sortedLater,
    sortCode = self.sortCode, killed = self.killed, missing = self.missing }
end

ecs.panel.registerType({
  name = "panel",
  title = "Runner",

  create = Runner.create,

  destroy = Runner.destroy,

  draw = Runner.draw,

  saveState = Runner.saveState,
})
