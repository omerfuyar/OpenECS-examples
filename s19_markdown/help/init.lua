-- A help panel that shows a Markdown file with the markdown standard plugin.
-- markdown.elements reads Markdown into a description of ui's elements, which ui.showDescription shows: headings, wrapped paragraphs,
-- lists, quotes, code and tables. markdown.parse gives the tree of nodes itself, for a plugin that shows Markdown its own way.

local ecs = require("ecs")
local markdown = require("markdown")

-- the file is read once; a plugin reads its own files by its folder
local file = assert(io.open(ecs.plugin.folder .. "help.md", "rb"))
local TEXT = file:read("a")
file:close()

local ui = require("ui")
local DESCRIPTION = assert(markdown.elements(TEXT))

-- the headings of the document, from its tree: each node has a type and its children
local function headings(node, list)
  list = list or {}

  for _, child in ipairs(node.children or {}) do
    if child.type == "heading" then
      list[#list + 1] = ("%d %s"):format(child.level, child.children[1].text)
    end

    headings(child, list)
  end

  return list
end

-- each panel's state is an object of Help, whose functions are methods
local Help = {}
Help.__index = Help

function Help.create(panel)
  return setmetatable({ panel = panel }, Help)
end

function Help:draw(surface)
  -- a click on a link, or Tab to it and Return, gave its address since the last draw; the id "" takes it from any text of the description,
  -- before the description is shown again, which forgets what was not taken
  local link = ui.take(self.panel, "", "onLink")

  if link then
    self.link = link.value
    self.panel.title = "Help: " .. link.value
  end

  -- a scroll shows the column of what the file holds, and scrolls what does not fit
  ui.showDescription(self.panel, surface, { type = "scroll", props = { id = "help", padding = 16 }, children = { DESCRIPTION --[[@as ui.Description]] } })
end

function Help:event(event)
  ui.event(self.panel, event)
end

function Help:destroy()
  ui.forget(self.panel)
end

-- what the test reads: the headings, and the type of each element the file became
function Help:saveState()
  local types = {}

  for i, child in ipairs(DESCRIPTION.children) do
    types[i] = child.type
  end

  return { headings = headings(markdown.parse(TEXT)), elements = types, link = self.link }
end

ecs.panel.registerType({
  name = "panel",
  title = "Help",

  create = Help.create,

  draw = Help.draw,

  event = Help.event,

  destroy = Help.destroy,

  saveState = Help.saveState,
})
