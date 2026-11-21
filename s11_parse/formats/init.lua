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

-- each panel's state is an object of Formats, whose functions are methods
local Formats = {}
Formats.__index = Formats

function Formats:convert()
  -- a function that fails gives nothing and why
  local text, problem = write(self.format, samples[self.format])
  local data = text and read(self.format, text)
  self.text = text or problem
  self.same = data ~= nil and write(self.format, data) == text
  self.panel.title = self.format
end

function Formats.create(panel, saved)
  local state = setmetatable({ panel = panel, format = saved and samples[saved.format] and saved.format or "Json" }, Formats)
  state:convert()

  -- a text that cannot be read gives nothing and why, with where it is
  local _, problem = parse.json.read('{ "name": "Paint", }}')
  state.problem = problem
  return state
end

function Formats:draw(surface)
  -- a text keeps its own lines; wrap also breaks them at spaces to fit the column, and a scroll shows what does not fit
  ui.show(self.panel, surface, ui.scroll({ id = "text", padding = 12, gap = 8 }, {
    ui.text(self.text, { wrap = true }),
    ui.text(self.same and "It reads back the same." or "It does not read back the same."),
    ui.text("A broken JSON text: " .. self.problem, { wrap = true }),
  }))
end

function Formats:event(event)
  ui.event(self.panel, event)
end

function Formats:destroy()
  ui.forget(self.panel)
end

function Formats:saveState()
  return { format = self.format, text = self.text, same = self.same, problem = self.problem }
end

ecs.panel.registerType({
  name = "panel",
  title = "Formats",
  stateVersion = 1,

  create = Formats.create,

  draw = Formats.draw,

  event = Formats.event,

  destroy = Formats.destroy,

  saveState = Formats.saveState,
})
