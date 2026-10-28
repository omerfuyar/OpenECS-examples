-- A terminal: a grid of characters from the textgrid standard plugin, which draws it with draw, and fills the panel at any size.
-- Typed text goes to a command line, and Return runs it: help, echo, bold, time and clear.
-- Ctrl and + or - change the font size, and Ctrl+0 sets it back: the grid draws at any size, and refits the panel.

local ecs = require("ecs")
local textgrid = require("textgrid")

local SIZE = 16 -- the font size at first, in layout units
local SMALLEST, LARGEST, STEP = 8, 48, 2
local PROMPT = "> "
local FOREGROUND, BACKGROUND = "#D0D0D0", "#101418"

local terminals = {} -- every open terminal's state, by its panel handle

-- each command gets the text after its name and gives the lines to print, and the style to print them in
local commands = {
  help = function()
    return "help, echo TEXT, bold TEXT, time, clear"
  end,
  echo = function(text)
    return text
  end,
  bold = function(text)
    return text, "bold"
  end,
  time = function()
    return os.date("%H:%M:%S") -- Lua's standard libraries work in plugins
  end,
}

-- runs a line, prints what it gives, and keeps it as the last output
local function run(terminal, line)
  local name, rest = line:match("^(%S*)%s*(.*)$")
  terminal.grid:print(PROMPT .. line .. "\n")

  if name == "clear" then
    terminal.grid:clear()
    terminal.output = ""
  elseif commands[name] then
    local style
    terminal.output, style = commands[name](rest)
    terminal.grid:style(style or "")
    terminal.grid:print(terminal.output)
    terminal.grid:style("")
    terminal.grid:print("\n")
  elseif name ~= "" then
    terminal.output = "unknown command: " .. name
    terminal.grid:print(terminal.output .. "\n")
  end
end

ecs.panel.registerType({
  name = "panel",
  title = "Terminal",

  create = function(panel)
    -- a grid is a handle that textgrid owns; the panel keeps it in its state, and Lua frees it with the state
    local terminal = { panel = panel, grid = textgrid.new(80, 24), line = "", output = "", size = SIZE }
    terminals[panel] = terminal
    terminal.grid:colors(FOREGROUND, BACKGROUND)
    terminal.grid:clear()
    terminal.grid:print("Type ")
    terminal.grid:style("bold underline")
    terminal.grid:print("help")
    terminal.grid:style("")
    terminal.grid:print(" and press Return. Wide characters, such as 漢字, take two cells.\n")
    terminal.grid:print("Ctrl and + or - change the font size, and Ctrl+0 sets it back.\n")
    panel:setTextInput(true)
    return terminal
  end,

  draw = function(state, surface)
    -- the grid takes as many cells as fit the panel; resizing wraps its lines again at the new width
    local columns, rows = textgrid.fit(surface.width / surface.scale, surface.height / surface.scale, state.size)
    state.grid:resize(math.max(columns, 1), math.max(rows, 1))

    -- the command line is written over the row of the cursor each time, so it never scrolls the grid
    local _, row = state.grid:cursor()
    state.grid:put(0, row, (PROMPT .. state.line):sub(-columns) .. string.rep(" ", columns))
    state.grid:setCursor(math.min(#PROMPT + #state.line, columns - 1), row)

    surface:fill(0, 0, surface.width, surface.height, BACKGROUND)
    textgrid.draw(surface, state.grid, 0, 0, state.size, true)
  end,

  event = function(state, event)
    if event.type == "text" then
      state.line = state.line .. event.text
    elseif event.type == "keyDown" and event.key == "Backspace" then
      state.line = state.line:sub(1, (utf8.offset(state.line, -1) or 1) - 1)
    elseif event.type == "keyDown" and event.key == "Return" then
      local _, row = state.grid:cursor()
      state.grid:setCursor(0, row)
      run(state, state.line)
      state.line = ""
    else
      return
    end

    state.panel:redraw()
  end,

  -- the last output and its first cells are saved, so the test can read them; a wide character's right half gives an empty text
  saveState = function(state)
    local _, row = state.grid:cursor()
    local cells, styles = {}, {}

    for column = 0, 5 do
      cells[column + 1], styles[column + 1] = state.grid:get(column, row - 1)
    end

    -- and the text of every row, one after another, for the test to find lines that wrap
    local columns, rows = state.grid:size()
    local screen = {}

    for row = 0, rows - 1 do
      for column = 0, columns - 1 do
        screen[#screen + 1] = state.grid:get(column, row)
      end
    end

    return { output = state.output, cells = cells, styles = styles, size = state.size, columns = columns, screen = table.concat(screen) }
  end,

  destroy = function(state)
    terminals[state.panel] = nil
  end,
})

-- the font size changes by a step, from SMALLEST to LARGEST; the next draw fits the grid to the panel at the new size
local function resize(step)
  return function(panel)
    local terminal = terminals[panel]

    if terminal then
      terminal.size = step == 0 and SIZE or math.min(math.max(terminal.size + step, SMALLEST), LARGEST)
      panel:redraw()
    end
  end
end

-- functions that keys run get the focused panel; the plugin binds them for its panel type, and the user can change the keys
assert(ecs.service.register({
  bigger = { sig = "void(handle<ecs.panel> panel)", doc = "Make the font larger", fn = resize(STEP) },
  smaller = { sig = "void(handle<ecs.panel> panel)", doc = "Make the font smaller", fn = resize(-STEP) },
  resetSize = { sig = "void(handle<ecs.panel> panel)", doc = "Set the font size back", fn = resize(0) },
}))

-- Ctrl and = is Ctrl and + on most keyboards; Shift+= gives + itself, and the keypad has its own keys
for key, service in pairs({ ["Ctrl+="] = "bigger", ["Ctrl+Shift+="] = "bigger", ["Ctrl+Keypad +"] = "bigger", ["Ctrl+-"] = "smaller", ["Ctrl+Keypad -"] = "smaller", ["Ctrl+0"] = "resetSize" }) do
  assert(ecs.key.bind("terminal.panel", key, "terminal." .. service))
end
