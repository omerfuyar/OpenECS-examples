-- Writes a table in one of parse's formats, reads the text back and writes it again: the two texts are the same.
-- Each format holds other values, so each panel has a table that fits its format.

local ecs = require("ecs")
local parse = require("parse")
local ui = require("ui")

local samples = {
  -- JSON and TOML hold nested tables, lists, numbers and booleans; parse writes named fields sorted by name, so a table always gives the same text
  Json = { name = "Paint", size = { width = 800, height = 600 }, scale = 1.5, dark = true, tools = { "brush", "eraser" } },
  Toml = { name = "Paint", size = { width = 800, height = 600 }, scale = 1.5, dark = true, tools = { "brush", "eraser" } },
  -- INI holds sections of keys, and reads every value back as a text
  Ini = { name = "Paint", size = { width = 800, height = 600 } },
  -- .env holds keys with their texts
  Env = { NAME = "Paint", GREETING = "Hello, world" },
  -- CSV holds rows of fields; a field with a comma or a quote goes in quotes
  Csv = { { "tool", "key" }, { "brush", "B" }, { "eraser, soft", "E" } },
}

-- each format is a namespace of parse, with its read and write: parse.json.read and parse.json.write, and so on;
-- json.write takes whether to indent, and csv's functions take a separator, where an empty one is a comma
local function write(format, data)
  if format == "Json" then
    return parse.json.write(data, true)
  elseif format == "Csv" then
    return parse.csv.write(data, "")
  end

  return parse[format:lower()].write(data)
end

local function read(format, text)
  if format == "Csv" then
    return parse.csv.read(text, "")
  end

  return parse[format:lower()].read(text)
end

local function convert(state)
  -- a function that fails gives nothing and why
  local text, problem = write(state.format, samples[state.format])
  local data = text and read(state.format, text)
  state.text = text or problem
  state.same = data ~= nil and write(state.format, data) == text
  state.panel.title = state.format
end

ecs.panel.registerType({
  name = "panel",
  title = "Formats",
  stateVersion = 1,

  create = function(panel, saved)
    local state = { panel = panel, format = saved and samples[saved.format] and saved.format or "Json" }
    convert(state)

    -- a text that cannot be read gives nothing and why, with where it is
    local _, problem = parse.json.read('{ "name": "Paint", }}')
    state.problem = problem
    return state
  end,

  draw = function(state, surface)
    -- a text keeps its own lines; wrap also breaks them at spaces to fit the column, and a scroll shows what does not fit
    ui.show(state.panel, surface, ui.scroll({ id = "text", padding = 12, gap = 8 }, {
      ui.text(state.text, { wrap = true }),
      ui.text(state.same and "It reads back the same." or "It does not read back the same."),
      ui.text("A broken JSON text: " .. state.problem, { wrap = true }),
    }))
  end,

  event = function(state, event)
    ui.event(state.panel, event)
  end,

  destroy = function(state)
    ui.forget(state.panel)
  end,

  saveState = function(state)
    return { format = state.format, text = state.text, same = state.same, problem = state.problem }
  end,
})
