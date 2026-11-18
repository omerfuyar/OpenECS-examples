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
local DESCRIPTION = markdown.elements(TEXT)

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

ecs.panel.registerType({
  name = "panel",
  title = "Help",

  create = function(panel)
    return { panel = panel }
  end,

  draw = function(state, surface)
    -- a click on a link, or Tab to it and Return, gave its address since the last draw; the id "" takes it from any text of the description,
    -- before the description is shown again, which forgets what was not taken
    local link = ui.take(state.panel, "", "onLink")

    if link then
      state.link = link.value
      state.panel.title = "Help: " .. link.value
    end

    -- a scroll shows the column of what the file holds, and scrolls what does not fit
    ui.showDescription(state.panel, surface, { type = "scroll", props = { id = "help", padding = 16 }, children = { DESCRIPTION } })
  end,

  event = function(state, event)
    ui.event(state.panel, event)
  end,

  destroy = function(state)
    ui.forget(state.panel)
  end,

  -- what the test reads: the headings, and the type of each element the file became
  saveState = function(state)
    local types = {}

    for i, child in ipairs(DESCRIPTION.children) do
      types[i] = child.type
    end

    return { headings = headings(markdown.parse(TEXT)), elements = types, link = state.link }
  end,
})
