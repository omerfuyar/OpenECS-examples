-- A panel that filters a log's lines with the regex standard plugin, as a log viewer would: the lines that match the typed pattern show,
-- each read into its parts by a pattern with named groups.
-- regex.compile reads a pattern once, and gives a handle whose methods use it: test, match, matchAll, replace, replaceFirst and split.

local ecs = require("ecs")
local ui = require("ui")
local regex = require("regex")

local LOG = {
  "2026-11-09 10:00:01 INFO  server started on port 8080",
  "2026-11-09 10:00:05 WARN  disk 91% full",
  "2026-11-09 10:01:12 ERROR request /api/items failed: timeout after 30s",
  "2026-11-09 10:02:40 INFO  user alice logged in",
  "2026-11-09 10:03:02 ERROR database locked",
  "2026-11-09 10:04:15 WARN  slow query took 2.4s",
}

-- a named group, (?<name>...), gives its text by name in the match's named table; positions are bytes from 1, as string.find gives
local LINE = assert(regex.compile("^(?<date>\\S+) (?<time>\\S+) (?<level>[A-Z]+)\\s+(?<message>.*)$"))

-- $3 is the third group's text, so a replacement can reorder what a pattern found
local DATE = assert(regex.compile("(\\d+)-(\\d+)-(\\d+)"))

-- a duration in seconds, such as 30s or 2.4s; matchAll finds every one, each after the last
local DURATION = assert(regex.compile("(\\d+(?:\\.\\d+)?)s\\b"))

-- what separates words: a run of blanks
local BLANKS = assert(regex.compile("\\s+"))

-- compiles the typed text, and keeps the lines it matches; i ignores case. A pattern that cannot be read gives nothing and why
local function filter(state)
  local source = state.exact and regex.escape(state.typed) or state.typed
  local pattern, problem = regex.compile(source, "i")
  state.problem = problem
  state.shown = {}

  for _, line in ipairs(pattern and LOG or {}) do
    if pattern:test(line) then
      local parts = LINE:match(line).named
      state.shown[#state.shown + 1] = { level = parts.level, text = ("%s  %-5s %s"):format(parts.time, parts.level, parts.message) }
    end
  end
end

ecs.panel.registerType({
  name = "panel",
  title = "Log filter",

  create = function(panel)
    local state = { panel = panel, typed = "error|warn", exact = false }
    filter(state)

    -- the day of the log, as 09.11.2026, and the words of its first message, split at runs of blanks
    state.day = DATE:replaceFirst(LOG[1]:sub(1, 10), "$3.$2.$1")
    state.words = BLANKS:split(LINE:match(LOG[1]).named.message)

    -- every duration in the log, and the log's numbers hidden: replace gives the new text and how many matches it replaced
    state.durations = {}

    for _, match in ipairs(DURATION:matchAll(table.concat(LOG, "\n"))) do
      state.durations[#state.durations + 1] = match.groups[1]
    end

    state.hidden, state.numbers = assert(regex.compile("\\d")):replace(LOG[2], "#")
    return state
  end,

  draw = function(state, surface)
    local lines = {}

    for _, line in ipairs(state.shown) do
      lines[#lines + 1] = ui.text(line.text, { font = "mono", color = line.level == "ERROR" and "accent" or "text" })
    end

    ui.show(state.panel, surface, ui.column({ padding = 12, gap = 8 }, {
      ui.text("The log of " .. state.day),
      ui.row({ gap = 8 }, {
        ui.field(state.typed, { id = "pattern", grow = 1, valid = state.problem == nil, onChange = function(text)
          state.typed = text
          filter(state)
        end }),
        ui.toggle(state.exact, { id = "exact", label = "Exact text", onChange = function(on)
          state.exact = on
          filter(state)
        end }),
      }),
      ui.text(state.problem or ("%d of %d lines match"):format(#state.shown, #LOG), { color = state.problem and "accent" or "textDim", wrap = true }),
      ui.scroll({ id = "lines", grow = 1, gap = 2 }, lines),
    }))
  end,

  event = function(state, event)
    ui.event(state.panel, event)
  end,

  destroy = function(state)
    ui.forget(state.panel)
  end,

  -- what the test reads
  saveState = function(state)
    local shown = {}

    for i, line in ipairs(state.shown) do
      shown[i] = line.text
    end

    return { typed = state.typed, exact = state.exact, shown = shown, problem = state.problem, day = state.day, words = state.words,
      durations = state.durations, hidden = state.hidden, numbers = state.numbers }
  end,
})
