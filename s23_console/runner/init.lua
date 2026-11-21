-- A runner built on the console: the console plugin keeps the entries that plugins add, each in a box of its level's colour,
-- stacks an entry that repeats the one before it, shows the links that a plugin gives an entry, and opens the file that an
-- entry names in the user's code editor, with the command of its setting console.editor.

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
  -- a run clears the console first, while its setting console.clearOnRun is on, as it is by default
  console.run()
  -- an entry may hold many lines; one such as "main.lua:3" names a file and a line, and the same entry twice in a row stacks
  console.add("Running main.lua\nstarted", "info")
  console.add("main.lua:3: attempt to call a nil value", "error", links)
  console.add("main.lua:3: attempt to call a nil value", "error", links)
end

-- empties the clipboard, so the test sees what the console's menu copies; many fills the console with more entries than it shows,
-- of which it builds only those in view
ecs.service.register({
  forget = { sig = "void()", doc = "Empty the clipboard", fn = function()
    ecs.clipboard.setText("")
  end },
  many = { sig = "void()", doc = "Add 500 entries", fn = function()
    for i = 1, 500 do
      console.add(("entry %d"):format(i), "info")
    end
  end },
})

ecs.panel.registerType({
  name = "panel",
  title = "Runner",
  create = function(panel)
    return { panel = panel }
  end,
  draw = function(state, surface)
    ui.show(state.panel, surface, ui.row({ padding = 8 }, { ui.button("Run", { id = "run", onClick = run }) }))
  end,
  event = function(state, event)
    ui.event(state.panel, event)
  end,
  -- the console's entries, the folder and the clipboard, for the test
  saveState = function()
    local entries = console.entries()
    return { entries = #entries, count = entries[#entries] and entries[#entries].count or 0, shown = shown, folder = ecs.plugin.folder,
      clipboard = ecs.clipboard.getText() }
  end,
  destroy = function(state)
    ui.forget(state.panel)
  end,
})
