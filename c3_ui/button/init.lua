-- A panel of controls built with the ui standard plugin: a button that counts its clicks, and the other elements ui offers.
-- A standard plugin ships with OpenECS for other plugins to build on: draw draws shapes and text, and ui builds user interfaces on it.

local ecs = require("ecs")

-- require with a plugin's name gives that plugin's functions; the manifest must depend on it, so it loads first
-- editors complete them from the definitions that the build writes, which .luarc.json names (README.md, "Editors")
local ui = require("ui")

-- a style is a table of the props of an element's look, kept in a variable so elements share it; an element's style prop takes it, and the
-- element's own props win. ui.styles gives ui's own styles, which its standard views use too: view, item, title, heading and note
local LABELED = { gap = 8 }
local STYLES = ui.styles()

local FRUITS = { "Apple", "Banana", "Cherry" }
-- more choices than a window holds, so the dropdown's popup scrolls
local ITEMS = {}
for i = 1, 40 do
  ITEMS[i] = "Item " .. i
end
local SIZES = { "S", "M", "L" }
local TABS = { "Options", "About", "Table" }
const ITEM_COUNT = 40
local TAGS = { "Lua", "C", "SDL", "Clay", "libffi", "stb" }

-- the Table tab's columns and rows; the panel sorts the rows, and the table shows them in its order
local COLUMNS = { { id = "name", title = "Fruit" }, { id = "price", title = "Price" }, { id = "stock", title = "In stock" } }
local FRUIT_ROWS = { { name = "Cherry", price = 4.5, stock = 12 }, { name = "Apple", price = 1.2, stock = 40 }, { name = "Banana", price = 0.8, stock = 25 } }
-- the colours of the graph of the stock below the table, and of its line at the stock to buy more at
local GRAPH_COLOR, LINE_COLOR = "#61AFEF", "#E06C75"

-- the nodes of the About tab's tree; a node with children opens and closes
local NODES = {
  {
    id = "src",
    label = "src",
    children = {
      { id = "main", label = "main.c" },
      { id = "lib",  label = "lib",   children = { { id = "util", label = "util.c" } } },
    }
  },
  { id = "readme", label = "README.md" },
}

-- lib holds a hundred files, so its tree is long when it is open
for i = 2, 100 do
  NODES[1].children[2].children[i] = { id = "f" .. i, label = ("file%d.c"):format(i) }
end

-- each panel's state is an object of Controls, whose functions are methods
local Controls = {}
Controls.__index = Controls

-- the tree's nodes: a node's marks are short labels at the end of its row, on or off; README.md has a star, and a padlock that
-- shows locked or open, which the panel keeps
function Controls:nodesOf()
  NODES[2].marks = {
    { id = "star", label = "Star", on = self.starred == true, tooltip = "A click stars the file, or takes the star off" },
    { id = "lock", label = { ui.icon(self.locked and "lock" or "lockOpen") }, on = self.locked == true, tooltip = "A click locks the file, or unlocks it" },
  }
  return NODES
end

-- the text that wraps, twice: alone in the column, and beside a label in a row
local NOTE = "Tab gives the keys to the next control and Shift+Tab to the one before. Return or Space presses the control that has them, " ..
  "Left and Right change a selector or a slider, and Escape takes the keys away. A field takes typing as soon as it has the keys. " ..
  "In a field, Home and End move the cursor to its start and end, Shift with them selects, and Ctrl+C, Ctrl+X and Ctrl+V copy, cut and paste."

-- the elements the test clicks, by id; their rectangles are saved, so the test finds them
local IDS = { "button", "tab", "sound", "volume", "size", "fruit", "item", "count", "item:2", "name", "note", "beside", "tree:src", "tree:main", "tree:readme:star",
  "tree:readme:lock", "icon:eye", "icon:eyeClosed", "icon:lock", "icon:lockOpen", "lockButton",
  "tree:lib", "tree:f100", "table:header", "table:1", "table:2", "table:title:name", "table:title:price", "graph", "about",
  "tint", "colors:heading", "tag:1", "tag:2", "tag:6", "file", "list" }

-- the rows of the Table tab, in the order the panel sorts them
function Controls:sorted()
  local rows = {}

  for i, row in ipairs(FRUIT_ROWS) do
    rows[i] = row
  end

  table.sort(rows, function(a, b)
    if self.ascending then
      return a[self.sort] < b[self.sort]
    end

    return a[self.sort] > b[self.sort]
  end)

  return rows
end

-- the stock of each row, in the table's order, for the graph
function Controls:stock()
  local values = {}

  for i, row in ipairs(self:sorted()) do
    values[i] = row.stock
  end

  return values
end

-- the state a new panel starts with: the value of each control, and the rectangles of the elements the test clicks
local START = {
  clicks = 0,
  sound = false,
  dark = true,
  volume = 0.5,
  kept = 0.5,
  size = 2,
  fruit = 1,
  item = 1,
  count = 3,
  tab = 1,
  selected = 1,
  name = "",
  file = "",
  node = "readme",
  nodes = { "readme" },
  open = {},
  sort = "name",
  ascending = true,
  tint = "#3366CC",
  colors = true,
  rects = {},
}

-- a copy of a table and of the tables in it, so each panel changes its own state, not START
local function copy(value)
  if type(value) ~= "table" then
    return value
  end

  local result = {}

  for key, item in pairs(value) do
    result[key] = copy(item)
  end

  return result
end

function Controls.create(panel)
  local controls = setmetatable(copy(START), Controls)
  controls.panel = panel
  -- the panel takes the tree's nodes that are dragged onto it, as data of the core's drag and drop
  panel:acceptDrops({ "example.node" })
  return controls
end

-- draw runs only when the panel needs drawing; a panel type that draws every frame says continuous = true
-- ui lays out and draws the elements that draw describes each time, so the panel keeps only its own state
function Controls:draw(surface)
  -- each callback changes the panel's self; ui then asks the core to draw the panel again
  local function set(key)
    return function(value)
      self[key] = value
    end
  end

  local items, tags = {}, {}

  for i, text in ipairs(TAGS) do
    tags[i] = ui.button(text, { id = "tag:" .. i })
  end

  -- a long list builds only the items in view and near it, which ui.range gives; the list gets count, its number of items, and first
  local first, last = ui.range(self.panel, "list", ITEM_COUNT)

  for i = first, last do
    items[#items + 1] = ui.text(("Item %d"):format(i), { id = "item:" .. i })
  end

  -- a right click that no other element takes reaches the root's onMenu, which opens a menu there, in layout units as ui.menu takes them
  local function menu(x, y)
    ui.menu(self.panel, x, y, {
      { label = "Add a click", onClick = function() self.clicks = self.clicks + 1 end },
      { line = true },
      { label = "Reset the clicks", enabled = self.clicks > 0, onClick = function() self.clicks = 0 end },
      -- an entry with entries is a submenu, which opens in place of the menu, below a row that goes back
      { label = "More", entries = {
        { label = "Add ten clicks", onClick = function() self.clicks = self.clicks + 10 end },
      } },
    })
  end

  ui.show(self.panel, surface, ui.column({ style = STYLES.view, onMenu = menu }, {
    ui.text(("Clicked %d times"):format(self.clicks), { style = STYLES.title }),
    -- a tooltip shows when the pointer rests on its element
    ui.button("Click me", {
      id = "button",
      tooltip = "Counts the clicks in the panel's title",
      onClick = function()
        self.clicks += 1
        self.panel.title = ("Controls (%d)"):format(self.clicks)
      end,
    }),
    ui.separator(),
    -- tabs choose what shows below them; the panel keeps the chosen one and describes only its elements
    ui.tabs(self.tab, TABS, { id = "tab", onSelect = set("tab") }),
    -- a table lines its cells up below its columns' titles; a click on a title sorts by that column, and a second one reverses the order
    TABS[self.tab] == "Table" and ui.column({ gap = 8 }, {
    ui.table(COLUMNS, self:sorted(),
      {
        id = "table",
        height = 110,
        grow = 0,
        stretch = true,
        border = "frame",
        sort = self.sort,
        ascending = self.ascending,
        selected = self.row,
        onSelect = set("row"),
        onSort = function(column)
          self.ascending = column ~= self.sort or not self.ascending
          self.sort, self.row = column, nil
        end
      }),
      -- a graph draws a bar for each number, in the rows' order, as high as its share of the highest; a line marks a value across it
      ui.graph(self:stock(), { id = "graph", height = 40, colors = { GRAPH_COLOR }, lines = { { value = 20, color = LINE_COLOR } } }),
    }) or
    -- a tree shows its open nodes' children below them; the panel keeps which nodes are open, and the chosen one
    TABS[self.tab] == "About" and ui.column({ gap = 8 }, {
      -- a text of spans mixes styles; a click on a span with a link gives the link to onLink
      ui.text({ "The controls of ", { text = "ui", bold = true }, ", each changing the panel's self: ", { text = "ui's design", link = "https://github.com/omerfuyar/OpenECS-std/blob/dev/DESIGN.md" } },
        { id = "about", color = "textDim", onLink = set("link") }),
      -- icons are small pictures drawn from shapes, a line of text high, in a colour
      ui.row({ gap = 8 }, {
        ui.icon("eye", { id = "icon:eye", tooltip = "Shown" }),
        ui.icon("eyeClosed", { id = "icon:eyeClosed", tooltip = "Hidden" }),
        ui.icon("lock", { id = "icon:lock", color = "accent", tooltip = "Locked" }),
        ui.icon("lockOpen", { id = "icon:lockOpen", tooltip = "Open" }),
        -- a label is a text, or spans of words and pictures, wherever one shows: a button's, a tree's node and mark, a section's title
        ui.button({ ui.icon(self.locked and "lock" or "lockOpen"), self.locked and " Unlock" or " Lock" },
          { id = "lockButton", onClick = function() self.locked = not self.locked end }),
      }),
      -- a tree is given every node, and builds only the rows in view and near it
      ui.tree(self:nodesOf(),
        {
          id = "tree",
          height = 110,
          grow = 0,
          border = "frame",
          open = self.open,
          -- the tree chooses many nodes: selected is the list of the chosen ones, and the first is where Up and Down move from;
          -- a press with Ctrl adds a node or takes it out, and one with Shift chooses the shown nodes from the first chosen one to it
          selected = self.nodes,
          onSelect = function(id, how, between)
            if how == "toggle" then
              local kept = {}

              for _, other in ipairs(self.nodes) do
                if other ~= id then
                  kept[#kept + 1] = other
                end
              end

              if #kept == #self.nodes then
                kept[#kept + 1] = id
              end

              self.nodes = kept
            elseif how == "range" then
              self.nodes = between
            else
              self.nodes = { id }
            end

            self.node = self.nodes[1]
          end,
          onToggle = function(id, open)
            self.open[id] = open or nil
          end,
          -- a click on a mark gives its node, the mark and its new self, and does not choose the node
          onMark = function(_, mark, on)
            if mark == "lock" then
              self.locked = on
            else
              self.starred = on
            end
          end,
          -- a right click on a node chooses it, unless it is chosen, and gives its id, as a menu about it would take it
          onMenu = function(id)
            self.menuNode = id
          end,
          -- a press on a node and a move of the pointer drag what onDrag gives, as data of the core's drag and drop
          onDrag = function(id)
            return "example.node", id
          end,
          -- a node dropped on the tree gives the node it landed on, and where: before it, into it, or after it, by where on its row
          onDrop = function(id, where, _, value)
            self.dropped = { node = value, where = where, on = id }
          end,
        }),
      -- a row with wrap = true puts the children that do not fit the rest of a line on the next line, as a toolbar does in a narrow panel;
      -- this one is in a narrow column, so its buttons take two lines
      ui.column({ width = 160 }, { ui.row({ wrap = true, gap = 4 }, tags) }),
    }) or ui.group({ title = "Options", gap = 8 }, {
      ui.toggle(self.sound, { id = "sound", label = "Sound", onChange = set("sound") }),
      ui.toggle(self.dark, { id = "dark", label = "Dark", look = "switch", onChange = set("dark") }),
      ui.row({ style = LABELED },
        { ui.text("Volume"), ui.slider(self.volume,
          -- onChange would get each value of a drag; onSubmit gets the one that its release ends on, which a tool keeps as one change,
          -- and the slider shows the dragged value until then
          { id = "volume", step = 0.1, grow = 1, onSubmit = function(value)
            self.volume, self.kept = value, value
          end }) }),
      ui.row({ style = LABELED },
        { ui.text("Size"), ui.selector(self.size, SIZES, { id = "size", onSelect = set("size") }) }),
      ui.row({ style = LABELED },
        { ui.text("Fruit"), ui.dropdown(self.fruit, FRUITS, { id = "fruit", onSelect = set("fruit") }) }),
      ui.row({ style = LABELED },
        { ui.text("Item"), ui.dropdown(self.item, ITEMS, { id = "item", onSelect = set("item") }) }),
      -- a number field takes a number from min to max: Return gives what is typed to onSubmit, and Up and Down change it by step;
      -- onChange would get the number at each edit
      ui.row({ style = LABELED },
        { ui.text("Count"), ui.number(self.count,
          { id = "count", min = 0, max = 10, step = 1, grow = 1, onSubmit = set("count") }) }),
      -- a section's heading shows and hides what is below it, at a click; the panel keeps whether it is open
      -- a colour element is a swatch, which a click opens in a picker; onChange gets the colour a press in the picker ends on
      ui.section("Colour", { id = "colors", open = self.colors, onToggle = set("colors") }, {
        ui.row({ style = LABELED }, { ui.text("Tint"), ui.color(self.tint, { id = "tint", onChange = set("tint") }) }),
      }),
    }),
    ui.list(
      {
        id = "list",
        count = ITEM_COUNT,
        first = first,
        height = 90,
        grow = 0,
        border = "frame",
        selected = self.selected,
        onSelect = set(
          "selected")
      },
      items),
    -- a path is a field with a button that opens the system's file dialog; the chosen file goes to onSubmit, as a typed path does at Return
    ui.row({ style = LABELED }, { ui.text("File"), ui.path(self.file, { id = "file", grow = 1, pattern = "lua", onSubmit = set("file") }) }),
    -- a field keeps what is typed while it has the keys; Left, Right, Home and End move its cursor, Shift with them selects, and Ctrl+C, Ctrl+X and Ctrl+V copy, cut and paste
    ui.row({ style = LABELED }, { ui.text("Name"), ui.field(self.name, { id = "name", grow = 1, placeholder = "Your name", onChange = set("name") }) }),
    -- text with wrap = true breaks into lines at the width of its column
    ui.text(NOTE, { id = "note", style = STYLES.note, wrap = true }),
    -- in a row, wrapped text and columns share what the other children leave, and a growing column's text breaks at the width it grows to
    ui.row({ gap = 8 }, { ui.text("Keys", { wrap = true }), ui.column({ grow = 1 }, { ui.text(NOTE, { id = "beside", style = STYLES.note, wrap = true }) }) }),
  }))

  -- the rectangles of the elements, in the panel's surface pixels; ui.rect gives nil for an element that is not shown, such as one on another tab
  for _, id in ipairs(IDS) do
    local rect = ui.rect(self.panel, id)
    self.rects[id] = rect and {
      x = rect.x * surface.scale,
      y = rect.y * surface.scale,
      width = rect.width * surface.scale,
      height = rect.height * surface.scale,
    }
  end
end

-- the panel's events go to ui, which calls the callbacks of the elements they reach; Up and Down choose a list's or the tree's next item and
-- the one before, and Right and Left open and close the tree's chosen node
function Controls:event(event)
  ui.event(self.panel, event)
end

function Controls:destroy()
  ui.forget(self.panel)
end

-- the values and the rectangles are saved, so the test can read them
function Controls:saveState()
  return {
    clicks = self.clicks,
    sound = self.sound,
    volume = self.volume,
    kept = self.kept,
    dropped = self.dropped,
    size = SIZES[self.size],
    fruit = FRUITS[self.fruit],
    item = ITEMS[self.item],
    count = self.count,
    tab = TABS[self.tab],
    tip = ui.tooltip(self.panel),
    inspected = ui.inspected(self.panel),
    selected = self.selected,
    name = self.name,
    file = self.file,
    node = self.node,
    nodes = self.nodes,
    menuNode = self.menuNode,
    starred = self.starred == true,
    locked = self.locked == true,
    open = self.open,
    sort = self.sort,
    ascending = self.ascending,
    row = self.row,
    first = TABS[self.tab] == "Table" and self:sorted()[1].name or nil,
    link = self.link,
    tint = self.tint,
    colors = self.colors,
    rects = self.rects
  }
end

ecs.panel.registerType({
  name = "panel",
  title = "Controls",

  create = Controls.create,

  draw = Controls.draw,

  event = Controls.event,

  destroy = Controls.destroy,

  saveState = Controls.saveState,
})
