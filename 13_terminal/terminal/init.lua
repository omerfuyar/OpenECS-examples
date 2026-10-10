-- A terminal: a grid of characters from the tty standard plugin, which fills the panel at any size.
-- Typed text goes to a command line, and Return runs it: help, echo, time and clear.

local ecs = require("ecs")
local tty = require("tty")

local SIZE = 16 -- the font size, in layout units
local PROMPT = "> "
local FOREGROUND, BACKGROUND = 0xFFD0D0D0, 0xFF101418

-- each command gets the text after its name and gives the lines to print
local commands = {
  help = function()
    return "help, echo TEXT, time, clear"
  end,
  echo = function(text)
    return text
  end,
  time = function()
    return os.date("%H:%M:%S") -- Lua's standard libraries work in plugins
  end,
}

-- runs a line, prints what it gives, and keeps it as the last output
local function run(terminal, line)
  local name, rest = line:match("^(%S*)%s*(.*)$")
  tty.print(terminal.grid, PROMPT .. line .. "\n")

  if name == "clear" then
    tty.clear(terminal.grid)
    terminal.output = ""
  elseif commands[name] then
    terminal.output = commands[name](rest)
    tty.print(terminal.grid, terminal.output .. "\n")
  elseif name ~= "" then
    terminal.output = "unknown command: " .. name
    tty.print(terminal.grid, terminal.output .. "\n")
  end
end

ecs.panel.registerType({
  name = "terminal.panel",
  title = "Terminal",

  create = function(panel)
    -- a grid is a handle that tty owns; the panel keeps it in its state, and Lua frees it with the state
    local terminal = { panel = panel, grid = tty.new(80, 24), line = "", output = "" }
    tty.colors(terminal.grid, FOREGROUND, BACKGROUND)
    tty.clear(terminal.grid)
    tty.print(terminal.grid, "Type help and press Return.\n")
    panel:setTextInput(true)
    return terminal
  end,

  draw = function(terminal, surface)
    -- the grid takes as many cells as fit the panel; resizing keeps the cells that still fit
    local columns, rows = tty.fit(surface.width / surface.scale, surface.height / surface.scale, SIZE)
    tty.resize(terminal.grid, math.max(columns, 1), math.max(rows, 1))

    -- the command line is written over the row of the cursor each time, so it never scrolls the grid
    local _, row = tty.cursor(terminal.grid)
    tty.put(terminal.grid, 0, row, (PROMPT .. terminal.line):sub(-columns) .. string.rep(" ", columns))
    tty.setCursor(terminal.grid, math.min(#PROMPT + #terminal.line, columns - 1), row)

    surface:fill(0, 0, surface.width, surface.height, BACKGROUND)
    tty.draw(surface, terminal.grid, 0, 0, SIZE, true)
  end,

  event = function(terminal, event)
    if event.type == "text" then
      terminal.line = terminal.line .. event.text
    elseif event.type == "keyDown" and event.key == "Backspace" then
      terminal.line = terminal.line:sub(1, (utf8.offset(terminal.line, -1) or 1) - 1)
    elseif event.type == "keyDown" and event.key == "Return" then
      local _, row = tty.cursor(terminal.grid)
      tty.setCursor(terminal.grid, 0, row)
      run(terminal, terminal.line)
      terminal.line = ""
    else
      return
    end

    terminal.panel:redraw()
  end,

  -- the last output is saved, so the test can read it
  saveState = function(terminal)
    return { output = terminal.output }
  end,
})
