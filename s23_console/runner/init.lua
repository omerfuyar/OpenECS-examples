-- A runner built on the console: the console plugin keeps the entries that plugins add, each in a box of its level's colour,
-- stacks an entry that repeats the one before it, shows the links that a plugin gives an entry, and opens the file that an
-- entry names in the user's code editor, with the command of its setting console.editor. Each entry names its source: here
-- "program" for what the program prints, and the plugin of each line of the log, which the console takes in whole. Each console
-- panel's Show dropdown shows the entries from a level up, at once.

local ecs = require("ecs")
local console = require("console")
local ui = require("ui")

-- a relative path in an entry starts at the console's folder
console.setFolder(ecs.plugin.folder)

-- how many times the error's own link was clicked
local shown = 0

-- a plugin may give an entry links of its own after its place, such as one to what raised the error
local links = { { text = "Show", tooltip = "Show what raised the error", onClick = function()
  shown += 1
end } }

local function run()
  -- the runner clears the console when a run starts: whether a tool clears it is the tool's own choice, as the console knows
  -- nothing of runs
  console.clear()
  -- an entry may hold many lines; one such as "main.lua:3" names a file and a line, and the same entry twice in a row stacks
  console.add("Running main.lua\nstarted", "info", nil, "program")
  console.add("main.lua:3: attempt to call a nil value", "error", links, "program")
  console.add("main.lua:3: attempt to call a nil value", "error", links, "program")
end

-- empties the clipboard, so the test sees what the console's menu copies; many fills the console with more entries than it shows,
-- of which it builds only those in view
ecs.service.register({
  forget = { sig = "void()", doc = "Empty the clipboard", fn = function()
    ecs.clipboard.setText("")
  end },
  warn = { sig = "void()", doc = "Log a warning, which the console takes in with every line of the log", fn = function()
    ecs.log.warn("The runner warns.")
  end },
  many = { sig = "void()", doc = "Add 500 entries", fn = function()
    for i = 1, 500 do
      console.add(("entry %d"):format(i), "info", nil, "program")
    end
  end },
})

-- each panel's state is an object of Runner, whose functions are methods
local Runner = {}
Runner.__index = Runner

function Runner.create(panel)
  return setmetatable({ panel = panel }, Runner)
end

function Runner:view()
  return ui.row({ padding = 8 }, { ui.button("Run", { id = "run", onClick = run }) })
end

-- the console's entries, the folder and the clipboard, for the test
function Runner:saveState()
  local entries = console.entries()
  return { entries = #entries, count = entries[#entries] and entries[#entries].count or 0, shown = shown, folder = ecs.plugin.folder,
    clipboard = ecs.clipboard.getText(), source = entries[#entries] and entries[#entries].source, text = entries[#entries] and entries[#entries].text }
end

ecs.panel.registerType(ui.panelType({
  name = "panel",
  title = "Runner",
  create = Runner.create,
  view = Runner.view,
  saveState = Runner.saveState,
}))
