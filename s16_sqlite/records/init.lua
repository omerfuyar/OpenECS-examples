-- A panel that keeps a table of fruits in a database with the sqlite standard plugin, and shows a query of it.
-- A database is a file, or here one in memory, which is gone when it closes. exec runs statements that give no rows, such as CREATE TABLE;
-- query runs one statement with parameters and gives its rows, each a table of its columns by name.

local ecs = require("ecs")
local draw = require("draw")
local sqlite = require("sqlite")

local FRUITS = { "cherry", "fig", "grape", "kiwi", "lemon", "mango", "peach", "plum" }

-- the rows that the panel shows: the fruits with their counts, the most first
local function load(state)
  state.rows = assert(state.database:query("SELECT name, count FROM fruits ORDER BY count DESC, name"))
  state.total = state.database:query("SELECT sum(count) AS total FROM fruits")[1].total
  state.panel:redraw()
end

-- adds a fruit; ? takes a list's items in order, so a value never becomes part of the SQL
local function add(state, name, count)
  assert(state.database:query("INSERT INTO fruits (name, count) VALUES (?, ?)", { name, count }))
  state.lastId = state.database:lastId()
end

ecs.panel.registerType({
  name = "panel",
  title = "Fruits",

  create = function(panel)
    local state = { panel = panel }
    state.database = assert(sqlite.open(":memory:"))
    assert(state.database:exec("CREATE TABLE fruits (id INTEGER PRIMARY KEY, name TEXT NOT NULL, count INTEGER NOT NULL)"))
    add(state, "apple", 3)
    add(state, "banana", 5)
    add(state, "orange", 2)

    -- :name takes a table's field of that name
    assert(state.database:query("UPDATE fruits SET count = count + :more WHERE name = :name", { name = "apple", more = 4 }))
    state.changed = state.database:changes()
    load(state)
    return state
  end,

  -- the database closes once its handle is gone; close closes it at once
  destroy = function(state)
    state.database:close()
  end,

  event = function(state, event)
    if event.type == "keyDown" and event.key == "Return" then
      add(state, FRUITS[(state.lastId - 3) % #FRUITS + 1], state.lastId + 1)
      load(state)
    end
  end,

  draw = function(state, surface)
    surface:fill(0, 0, surface.width, surface.height, "background")
    local font, y = draw.font("ui"), 16

    for _, row in ipairs(state.rows) do
      draw.text(surface, font, ("%-8s %d"):format(row.name, row.count), 16, y, 18, "text")
      y = y + 26
    end

    draw.text(surface, font, ("%d fruits; Return adds one"):format(state.total), 16, y, 18, "textDim")
  end,

  -- what the test reads
  saveState = function(state)
    return { rows = state.rows, total = state.total, changed = state.changed }
  end,
})
