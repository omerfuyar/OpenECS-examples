-- A tool of notes, built on the files panel: the files plugin shows a folder and does what a files panel does, and the
-- tool tells it which folder, how a file opens and which files its New makes. Here a note opens in a panel of the tool's own.

local ecs = require("ecs")
local files = require("files")
local ui = require("ui")

local folder = ecs.plugin.folder .. "folder/"
local opened = "" -- the last file that the files panel opened, by its path in the folder
local panels = {} ---@type table<ecs.Panel, boolean>

local function redraw()
  for panel in pairs(panels) do
    panel:redraw()
  end
end

-- the folder that the files panel shows; a path ends with a slash
files.setFolder(folder)

-- handlers are the tool's part: files calls them with a file's path in the folder, and does the rest itself
files.setHandlers({
  open = function(path)
    opened = path
    redraw()
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

ecs.panel.registerType({
  name = "opened",
  title = "Opened",
  create = function(panel)
    panels[panel] = true
    return { panel = panel }
  end,
  draw = function(state, surface)
    local text = "Click a note twice to open it."
    if opened ~= "" then
      local file = io.open(folder .. opened, "rb")
      text = opened .. "\n\n" .. (file and file:read("a") or "")
      if file then
        file:close()
      end
    end
    ui.show(state.panel, surface, ui.column({ padding = 8 }, { ui.text(text, { wrap = true }) }))
  end,
  event = function(state, event)
    ui.event(state.panel, event)
  end,
  saveState = function()
    return { opened = opened, folder = folder }
  end,
  destroy = function(state)
    ui.forget(state.panel)
    panels[state.panel] = nil
  end,
})
