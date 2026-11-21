-- A viewer that shows source files with the syntax standard plugin: tree-sitter reads each file, and its highlights become ui's spans,
-- each line a text in the mono font. The colours of the kinds are syntax's settings, such as syntax.colorKeyword, which a theme may set.

local ecs = require("ecs")
local syntax = require("syntax")
local ui = require("ui")

-- the files it shows: two samples and its own code; a plugin reads its own files by its folder
local FILES = { "sample.c", "init.lua", "sample.json" }

local function read(name)
  local file = assert(io.open(ecs.plugin.folder .. name, "rb"))
  local text = file:read("a")
  file:close()
  return text
end

-- each panel's state is an object of Source, whose functions are methods
local Source = {}
Source.__index = Source

-- the file's language comes from its name, and spans gives a list of spans for each line
function Source:load(file)
  local name = FILES[file]
  local language = syntax.languageOf(name)
  self.file, self.name, self.language = file, name, language
  self.lines = assert(syntax.spans(language, read(name)))
  self.panel.title = name
  self.panel:redraw()
end

function Source.create(panel)
  local state = setmetatable({ panel = panel }, Source)
  state:load(1)
  return state
end

function Source:draw(surface)
  local lines = {}

  for i, spans in ipairs(self.lines) do
    lines[i] = ui.text(spans, { font = "mono" })
  end

  ui.show(self.panel, surface, ui.column({ padding = 12, gap = 8 }, {
    ui.selector(self.file, FILES, { id = "file", onSelect = function(file)
      self:load(file)
    end }),
    ui.scroll({ id = "code", grow = 1 }, lines),
  }))
end

function Source:event(event)
  ui.event(self.panel, event)
end

function Source:destroy()
  ui.forget(self.panel)
end

-- what the test reads: the file and the kinds of a line of each sample, from highlight's ranges
function Source:saveState()
  local kinds = {}

  for _, range in ipairs(assert(syntax.highlight("c", "int main(void) { return 0; } // done"))) do
    kinds[#kinds + 1] = range.kind
  end

  return { name = self.name, language = self.language, lines = #self.lines, kinds = kinds, languages = syntax.languages() }
end

ecs.panel.registerType({
  name = "panel",
  title = "Viewer",

  create = Source.create,

  draw = Source.draw,

  event = Source.event,

  destroy = Source.destroy,

  saveState = Source.saveState,
})
