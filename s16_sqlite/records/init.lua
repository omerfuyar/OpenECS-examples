-- A panel that keeps a table of fruits in a database with the sqlite standard plugin, and shows a query of it.
-- A database is a file, or here one in memory, which is gone when it closes. exec runs statements that give no rows, such as CREATE TABLE;
-- query runs one statement with parameters and gives its rows, each a table of its columns by name.

local ecs = require("ecs")
local draw = require("draw")
local sqlite = require("sqlite")

local FRUITS = { "cherry", "fig", "grape", "kiwi", "lemon", "mango", "peach", "plum" }

-- each panel's state is an object of Records, whose functions are methods
local Records = {}
Records.__index = Records

-- the rows that the panel shows: the fruits with their counts, the most first
function Records:load()
  self.rows = assert(self.database:query("SELECT name, count FROM fruits ORDER BY count DESC, name"))
  self.total = self.database:query("SELECT sum(count) AS total FROM fruits")[1].total
  self.panel:redraw()
end

-- adds a fruit; ? takes a list's items in order, so a value never becomes part of the SQL
function Records:add(name, count)
  assert(self.database:query("INSERT INTO fruits (name, count) VALUES (?, ?)", { name, count }))
  self.lastId = self.database:lastId()
end

function Records.create(panel)
  local state = setmetatable({ panel = panel }, Records)
  state.database = assert(sqlite.open(":memory:"))
  assert(state.database:exec("CREATE TABLE fruits (id INTEGER PRIMARY KEY, name TEXT NOT NULL, count INTEGER NOT NULL)"))
  state:add("apple", 3)
  state:add("banana", 5)
  state:add("orange", 2)

  -- :name takes a table's field of that name
  assert(state.database:query("UPDATE fruits SET count = count + :more WHERE name = :name", { name = "apple", more = 4 }))
  state.changed = state.database:changes()
  state:load()
  return state
end

-- the database closes once its handle is gone; close closes it at once
function Records:destroy()
  self.database:close()
end

function Records:event(event)
  if event.type == "keyDown" and event.key == "Return" then
    self:add(FRUITS[(self.lastId - 3) % #FRUITS + 1], self.lastId + 1)
    self:load()
  end
end

function Records:draw(surface)
  surface:fill(0, 0, surface.width, surface.height, "background")
  local font, y = draw.font("ui"), 16

  for _, row in ipairs(self.rows) do
    draw.text(surface, font, ("%-8s %d"):format(row.name, row.count), 16, y, 18, "text")
    y += 26
  end

  draw.text(surface, font, ("%d fruits; Return adds one"):format(self.total), 16, y, 18, "textDim")
end

-- what the test reads
function Records:saveState()
  return { rows = self.rows, total = self.total, changed = self.changed }
end

ecs.panel.registerType({
  name = "panel",
  title = "Fruits",

  create = Records.create,

  destroy = Records.destroy,

  event = Records.event,

  draw = Records.draw,

  saveState = Records.saveState,
})
