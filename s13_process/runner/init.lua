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

-- takes what the started program wrote since the last time; once it exited, the timer stops
local function poll(state)
  lines(state.program:read(), state.lines)
  lines(state.program:readErrors(), state.errors)
  local exited, code = state.program:exited()

  -- what it wrote before it exited may still wait, so it is read once more
  if exited then
    lines(state.program:read(), state.lines)
    lines(state.program:readErrors(), state.errors)
    state.code = code
    state.timer:stop()
  end

  state.panel:redraw()
end

ecs.panel.registerType({
  name = "panel",
  title = "Runner",

  create = function(panel)
    local state = { panel = panel, lines = {}, errors = {} }

    -- run gives a program its input, which sort reads to the end, and waits for its output
    state.sorted = lines(process.run(shell("sort"), "", "b\na\n"), {})

    -- start gives a handle of the program; its methods read, write, kill it and tell whether it exited
    local program, problem = process.start(shell("echo one && echo two && echo three 1>&2"), "")
    state.program = assert(program, problem)
    state.timer = ecs.timer.start(0.05, true, function()
      poll(state)
    end)

    return state
  end,

  -- a program whose handle is gone is killed, so none is left behind
  destroy = function(state)
    state.timer:stop()
  end,

  draw = function(state, surface)
    surface:fill(0, 0, surface.width, surface.height, "background")
    local font, y = draw.font("ui"), 16

    local function show(text, color)
      draw.text(surface, font, text, 16, y, 18, color)
      y = y + 26
    end

    show("sort gave: " .. table.concat(state.sorted, ", "), "text")

    for _, line in ipairs(state.lines) do
      show(line, "text")
    end

    for _, line in ipairs(state.errors) do
      show(line, "accent")
    end

    show(state.code and ("exited with " .. state.code) or "running", "textDim")
  end,

  -- what the test reads
  saveState = function(state)
    return { sorted = state.sorted, lines = state.lines, errors = state.errors, code = state.code }
  end,
})
