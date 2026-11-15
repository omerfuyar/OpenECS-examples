-- A runner built on the console: the console plugin keeps the lines that plugins add, colours them by level, and opens
-- the file that a line names in the user's code editor, with the command of its setting console.editor.

local ecs = require("ecs")
local console = require("console")
local ui = require("ui")

-- a relative path in a line starts at the console's folder
console.setFolder(ecs.plugin.folder)

local function run()
  -- each line of a text is a line of the console; a line such as "main.lua:3" names a file and a line
  console.add("Running main.lua\nstarted", "info")
  console.add("main.lua:3: attempt to call a nil value", "error")
end

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
  -- the console's lines and the folder, for the test
  saveState = function()
    return { lines = #console.lines(), folder = ecs.plugin.folder }
  end,
  destroy = function(state)
    ui.forget(state.panel)
  end,
})
