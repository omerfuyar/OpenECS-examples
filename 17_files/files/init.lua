-- Browses folders and shows the start of a file. Lua plugins have Lua's standard libraries, so io reads files;
-- the fs standard plugin does what io cannot: it lists folders and tells what a path is.

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
    entry.label = entry.type == "folder" and entry.name .. "/" or entry.name
    table.insert(browser.entries, entry.type == "folder" and 1 or #browser.entries + 1, entry)
  end
end

local function open(browser, folder)
  browser.folder = folder
  browser.text = ""
  read(browser)
  browser.panel:setTitle(folder:match("([^/]+)/$") or folder)
  browser.panel:redraw()
end

ecs.panel.registerType({
  name = "files.panel",
  title = "Files",
  stateVersion = 1,

  -- the panel starts in the folder it was in, or in this plugin's folder
  create = function(panel, saved)
    local browser = { panel = panel }
    open(browser, saved and fs.info(saved.folder) and saved.folder or ecs.plugin.folder)
    return browser
  end,

  draw = function(browser, surface)
    local rows = {
      -- the folder above, unless this is the top folder
      browser.folder ~= "/" and ui.button("..", {
        onClick = function()
          open(browser, browser.folder:gsub("[^/]+/$", ""))
        end,
      }) or ui.space({ height = 0 }),
    }

    for _, entry in ipairs(browser.entries) do
      rows[#rows + 1] = ui.row({
        padding = 4,
        hoverBackground = "accent",
        onClick = function()
          if entry.type == "folder" then
            open(browser, browser.folder .. entry.name .. "/")
          else
            browser.text = preview(browser.folder .. entry.name)
          end
        end,
      }, {
        ui.text(entry.label, { grow = 1 }),
        ui.text(entry.type == "file" and ("%d bytes"):format(entry.size) or ""),
      })
    end

    ui.show(browser.panel, surface, ui.row({ padding = 12, gap = 12 }, {
      ui.scroll({ id = "entries", grow = 1 }, rows),
      ui.column({ grow = 1 }, { ui.text(browser.text) }),
    }))
  end,

  event = function(browser, event)
    ui.event(browser.panel, event)
  end,

  destroy = function(browser)
    ui.forget(browser.panel)
  end,

  saveState = function(browser)
    local names = {}

    for _, entry in ipairs(browser.entries) do
      names[#names + 1] = entry.label
    end

    return { folder = browser.folder, names = names }
  end,
})
