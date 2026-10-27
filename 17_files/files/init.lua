-- Browses folders and shows the start of a file. Lua plugins have Lua's standard libraries: io reads and writes files, and os renames and removes them.
-- The fs standard plugin does only what those cannot: it lists folders, tells what a path is, makes folders, copies files and watches folders.

local ecs = require("ecs")
local fs = require("fs")
local ui = require("ui")

-- the first lines of a text file, read with Lua's io library
local function preview(path)
  local file = io.open(path, "r")

  if file == nil then
    return "Cannot read the file."
  end

  local lines = {}

  for line in file:lines() do
    lines[#lines + 1] = line

    if #lines == 12 then
      break
    end
  end

  file:close()
  return table.concat(lines, "\n")
end

-- the folder's entries, folders first, each with a name to show
local function read(browser)
  browser.entries = {}

  for _, entry in ipairs(fs.list(browser.folder, "") or {}) do
    local label = entry.type == "folder" and entry.name .. "/" or entry.name
    table.insert(browser.entries, entry.type == "folder" and 1 or #browser.entries + 1, { name = entry.name, type = entry.type, size = entry.size, label = label })
  end
end

local function open(browser, folder)
  if browser.watch ~= nil then
    browser.watch:stop()
  end

  browser.folder = folder
  browser.text = ""
  read(browser)

  -- the list is read again when an entry of the folder is added, removed or changed
  browser.watch = fs.watch(folder, function()
    read(browser)
    browser.panel:redraw()
  end)

  browser.panel.title = folder:match("([^/]+)/$") or folder
  browser.panel:redraw()
end

ecs.panel.registerType({
  name = "panel",
  title = "Files",
  stateVersion = 1,

  -- the panel starts in the folder it was in, or in this plugin's folder
  create = function(panel, saved)
    local browser = { panel = panel }
    open(browser, saved and fs.info(saved.folder) and saved.folder or ecs.plugin.folder)
    return browser
  end,

  draw = function(state, surface)
    local rows = {
      -- the folder above, unless this is the top folder
      state.folder ~= "/" and ui.button("..", {
        onClick = function()
          open(state, state.folder:gsub("[^/]+/$", ""))
        end,
      }) or ui.space({ height = 0 }),
    }

    for _, entry in ipairs(state.entries) do
      rows[#rows + 1] = ui.row({
        padding = 4,
        hoverBackground = "accent",
        onClick = function()
          if entry.type == "folder" then
            open(state, state.folder .. entry.name .. "/")
          else
            state.text = preview(state.folder .. entry.name)
          end
        end,
      }, {
        ui.text(entry.label, { grow = 1 }),
        ui.text(entry.type == "file" and ("%d bytes"):format(entry.size) or ""),
      })
    end

    ui.show(state.panel, surface, ui.row({ padding = 12, gap = 12 }, {
      ui.scroll({ id = "entries", grow = 1 }, rows),
      ui.column({ grow = 1 }, { ui.text(state.text) }),
    }))
  end,

  event = function(state, event)
    ui.event(state.panel, event)
  end,

  destroy = function(state)
    if state.watch ~= nil then
      state.watch:stop()
    end

    ui.forget(state.panel)
  end,

  saveState = function(state)
    local names = {}

    for _, entry in ipairs(state.entries) do
      names[#names + 1] = entry.label
    end

    return { folder = state.folder, names = names }
  end,
})
