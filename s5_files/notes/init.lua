-- A tool of notes, built on the files panel: the files plugin shows a folder and does what a files panel does, and the
-- tool tells it which folder, what a click and a double click do, and which files its New makes. Here a click shows a
-- note's first line, and a double click opens the note, both in a panel of the tool's own. Lua's io reads the notes.
-- The panel follows the folder with fs's watch, so a note that another program adds shows in it too. Show in Files chooses the
-- opened note in the files panel, as a tool shows there the file of what the user works on, unless the panel is locked.

local ecs = require("ecs")
local files = require("files")
local ui = require("ui")

local folder = ecs.plugin.folder .. "folder/"
local opened = "" -- the last file that the files panel opened, by its path in the folder
local chosen = "" -- the file that a click chose

-- the plugin's own event, which its panels redraw on
ecs.event.declare("shown", "A click chose a note, or a double click opened one: its path in the folder")

-- the folder that the files panel shows; a path ends with a slash
files.setFolder(folder)

-- handlers are the tool's part: files calls them with a file's path in the folder, and does the rest itself
files.setHandlers({
  -- a click, or Up and Down, chooses a file
  choose = function(path)
    chosen = path
    ecs.event.emit("notes.shown", path)
  end,
  -- a double click opens it
  open = function(path)
    opened = path
    ecs.event.emit("notes.shown", path)
  end,
  -- New offers Folder and File, and these kinds between them; make gets the path that the panel's name field gives
  kinds = {
    { label = "Note", make = function(path)
      local file = io.open(folder .. path .. ".txt", "wb")
      if not file then
        return false, "The note could not be made."
      end
      file:write("A new note.\n")
      file:close()
      return true
    end },
  },
})

-- each panel's state is an object of Notes, whose functions are methods
local Notes = {}
Notes.__index = Notes

function Notes.create(panel)
  return setmetatable({ panel = panel }, Notes)
end

function Notes:view()
  local text = "Click a note to see its first line, and double-click it to open it."
  if chosen ~= "" and opened ~= chosen then
    local file = io.open(folder .. chosen, "rb")
    text = chosen .. ": " .. (file and file:read("l") or "")
    if file then
      file:close()
    end
  elseif opened ~= "" then
    local file = io.open(folder .. opened, "rb")
    text = opened .. "\n\n" .. (file and file:read("a") or "")
    if file then
      file:close()
    end
  end
  -- Show in Files shows the opened note in the files panel, unless the panel is locked
  return ui.column({ padding = 8, gap = 8 }, {
    ui.button("Show in files", { id = "show", tooltip = "Choose the opened note in the files panel", onClick = function()
      files.reveal(opened)
    end }),
    ui.text(text, { wrap = true }),
  })
end

function Notes:saveState()
  return { opened = opened, chosen = chosen, folder = folder }
end

ecs.panel.registerType(ui.panelType({
  name = "opened",
  title = "Opened",
  redrawOn = { "notes.shown" },
  create = Notes.create,
  view = Notes.view,
  saveState = Notes.saveState,
}))
