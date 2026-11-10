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

-- the file's language comes from its name, and spans gives a list of spans for each line
local function load(state, name)
  local language = syntax.languageOf(name)
  state.name, state.language = name, language
  state.lines = assert(syntax.spans(language, read(name)))
  state.panel.title = name
  state.panel:redraw()
end

ecs.panel.registerType({
  name = "panel",
  title = "Viewer",

  create = function(panel)
    local state = { panel = panel }
    load(state, FILES[1])
    return state
  end,

  draw = function(state, surface)
    local lines = {}

    for i, spans in ipairs(state.lines) do
      lines[i] = ui.text(spans, { font = "mono" })
    end

    ui.show(state.panel, surface, ui.column({ padding = 12, gap = 8 }, {
      ui.selector(state.name, FILES, { id = "file", onChange = function(name)
        load(state, name)
      end }),
      ui.scroll({ id = "code", grow = 1 }, lines),
    }))
  end,

  event = function(state, event)
    ui.event(state.panel, event)
  end,

  destroy = function(state)
    ui.forget(state.panel)
  end,

  -- what the test reads: the file and the kinds of a line of each sample, from highlight's ranges
  saveState = function(state)
    local kinds = {}

    for _, range in ipairs(assert(syntax.highlight("c", "int main(void) { return 0; } // done"))) do
      kinds[#kinds + 1] = range.kind
    end

    return { name = state.name, language = state.language, lines = #state.lines, kinds = kinds, languages = syntax.languages() }
  end,
})
