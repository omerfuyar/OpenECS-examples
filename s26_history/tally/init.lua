-- A count and a level, whose every change goes into a history (OpenECS-std DESIGN 34): Ctrl+Z and Ctrl+Y undo and redo them in the panel, and
-- the History panel lists them. tally_c is the same in C.

local ecs = require("ecs")
local ui = require("ui")
local history = require("history")

local STYLES = ui.styles()

-- one history for the plugin's panels; a tool with documents would open one for each
local h = history.open("tally")

local Tally = {}
Tally.__index = Tally

function Tally.create(panel)
  local self = setmetatable({ panel = panel, count = 0, level = 0.5 }, Tally)
  -- Ctrl+Z and Ctrl+Y in this panel act on the plugin's history
  history.use(panel, h)
  return self
end

-- adds to the count, and records how to take it back and make it again; the tag names what the record changes, for drop
function Tally:add(amount)
  self.count = self.count + amount
  history.push(h, ("Add %d"):format(amount), "", { "count" }, function()
    self.count = self.count - amount
    self.panel:redraw()
  end, function()
    self.count = self.count + amount
    self.panel:redraw()
  end, nil)
end

function Tally:view()
  return ui.column({ style = STYLES.view, gap = 8 }, {
    ui.text(("Count %d, level %.2f"):format(self.count, self.level), { id = "count", style = STYLES.title }),
    ui.row({ gap = 8 }, {
      ui.button("Add one", { id = "add", onClick = function() self:add(1) end }),
      -- a change whose undo fails: the history reports it and clears itself
      ui.button("Break", { id = "break", onClick = function()
        history.push(h, "Break", "", {}, function() error("this change cannot be undone") end, function() end, nil)
      end }),
      -- the counts' records go, as when what they changed was replaced from outside
      ui.button("Forget the counts", { id = "forget", onClick = function() history.drop(h, "count") end }),
    }),
    -- each step of a drag is a change of one value; the merge key joins them into one record
    ui.slider(self.level, { id = "level", onChange = function(level)
      history.change(h, "Level", "level", self.level, level, function(value)
        self.level = value
        self.panel:redraw()
      end, nil)
    end }),
  })
end

local IDS = { "add", "break", "forget", "level" }

-- not read back; the test reads the panel's values, its history, and where its elements are, in layout units, here
function Tally:saveState()
  local rects = {}

  for _, id in ipairs(IDS) do
    rects[id] = ui.rect(self.panel, id)
  end

  return { count = self.count, level = self.level, history = history.state(h), rects = rects }
end

-- a panel that keeps no history of its own: Ctrl+Z and Ctrl+Y in it act on the tool's default history, which tally_c names, and its buttons
-- name another one or none; the definitions do not let a handle be nil yet (OpenECS TODO), so the call with nil silences the check
local Note = {}
Note.__index = Note

function Note.create(panel)
  return setmetatable({ panel = panel }, Note)
end

function Note:view()
  return ui.column({ style = STYLES.view, gap = 8 }, {
    ui.text("This panel keeps no history: Ctrl+Z here undoes the tool's default one.", { style = STYLES.note, wrap = true }),
    ui.button("Default: tally", { id = "tally", onClick = function() history.useDefault(h) end }),
    ui.button("No default", { id = "none", onClick = function()
      history.useDefault(nil)
    end }),
  })
end

-- not read back; the test reads where the buttons are, in layout units, here
function Note:saveState()
  return { rects = { tally = ui.rect(self.panel, "tally"), none = ui.rect(self.panel, "none") } }
end

ecs.panel.registerType(ui.panelType({
  name = "note",
  title = "Note",
  create = Note.create,
  view = Note.view,
  saveState = Note.saveState,
}))

ecs.panel.registerType(ui.panelType({
  name = "panel",
  title = "Tally",
  redrawOn = { "history.changed" },
  create = Tally.create,
  view = Tally.view,
  saveState = Tally.saveState,
}))
