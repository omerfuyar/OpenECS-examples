-- A panel of controls built with the ui standard plugin: a button that counts its clicks, and the other elements ui offers.
-- A standard plugin ships with OpenECS for other plugins to build on: draw draws shapes and text, and ui builds user interfaces on it.

local ecs = require("ecs")

-- require with a plugin's name gives that plugin's functions; the manifest must depend on it, so it loads first
-- editors complete them from the definitions that the build writes, which .luarc.json names (README.md, "Editors")
local ui = require("ui")

-- a style is a look that elements share: the props of size, room, colour and font. ui.style gives back its name, which a variable keeps, and an
-- element's style prop names it; the element's own props win. Its name has a dot, and any plugin may use it, so a tool's plugins share a look
local LABELED = ui.style("button.labeled", { gap = 8 })

local FRUITS = { "Apple", "Banana", "Cherry" }
local SIZES = { "S", "M", "L" }
local TABS = { "Options", "About", "Table" }
local ITEMS = { "First item", "Second item", "Third item" }

-- the Table tab's columns and rows; the panel sorts the rows, and the table shows them in its order
local COLUMNS = { { id = "name", title = "Fruit" }, { id = "price", title = "Price" }, { id = "stock", title = "In stock" } }
local FRUIT_ROWS = { { name = "Cherry", price = 4.5, stock = 12 }, { name = "Apple", price = 1.2, stock = 40 }, { name = "Banana", price = 0.8, stock = 25 } }

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

-- the elements the test clicks, by id; their rectangles are saved, so the test finds them
local IDS = { "button", "tab", "sound", "volume", "size", "fruit", "count", "item:2", "name", "note", "tree:src",
  "tree:lib", "table:header", "table:1", "table:2", "table:title:name", "table:title:price", "about" }

-- the rows of the Table tab, in the order the panel sorts them
local function sorted(controls)
  local rows = {}

  for i, row in ipairs(FRUIT_ROWS) do
    rows[i] = row
  end

  table.sort(rows, function(a, b)
    if controls.ascending then
      return a[controls.sort] < b[controls.sort]
    end

    return a[controls.sort] > b[controls.sort]
  end)

  return rows
end

-- the state a new panel starts with: the value of each control, and the rectangles of the elements the test clicks
local START = {
  clicks = 0,
  sound = false,
  dark = true,
  volume = 0.5,
  size = 2,
  fruit = 1,
  count = 3,
  tab = 1,
  selected = 1,
  name = "",
  node = "readme",
  open = {},
  sort = "name",
  ascending = true,
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

ecs.panel.registerType({
  name = "panel",
  title = "Controls",

  create = function(panel)
    local controls = copy(START)
    controls.panel = panel
    return controls
  end,

  -- draw runs only when the panel needs drawing; a panel type that draws every frame says continuous = true
  -- ui lays out and draws the elements that draw describes each time, so the panel keeps only its own state
  draw = function(state, surface)
    -- each callback changes the panel's state; ui then asks the core to draw the panel again
    local function set(key)
      return function(value)
        state[key] = value
      end
    end

    local items = {}

    for i, text in ipairs(ITEMS) do
      items[i] = ui.text(text, { id = "item:" .. i })
    end

    -- ui has styles of its own, which its standard views use too: view, item, title, heading and note
    ui.show(state.panel, surface, ui.column({ style = "view" }, {
      ui.text(("Clicked %d times"):format(state.clicks), { style = "title" }),
      -- a tooltip shows when the pointer rests on its element
      ui.button("Click me", {
        id = "button",
        tooltip = "Counts the clicks in the panel's title",
        onClick = function()
          state.clicks = state.clicks + 1
          state.panel.title = ("Controls (%d)"):format(state.clicks)
        end,
      }),
      ui.separator(),
      -- tabs choose what shows below them; the panel keeps the chosen one and describes only its elements
      ui.tabs(state.tab, TABS, { id = "tab", onSelect = set("tab") }),
      -- a table lines its cells up below its columns' titles; a click on a title sorts by that column, and a second one reverses the order
      TABS[state.tab] == "Table" and
      ui.table(COLUMNS, sorted(state),
        {
          id = "table",
          height = 110,
          grow = 0,
          stretch = true,
          border = "tabShown",
          sort = state.sort,
          ascending = state.ascending,
          selected = state.row,
          onSelect = set("row"),
          onSort = function(column)
            state.ascending = column ~= state.sort or not state.ascending
            state.sort, state.row = column, nil
          end
        }) or
      -- a tree shows its open nodes' children below them; the panel keeps which nodes are open, and the chosen one
      TABS[state.tab] == "About" and ui.column({ gap = 8 }, {
        -- a text of spans mixes styles; a click on a span with a link gives the link to onLink
        ui.text({ "The controls of ", { text = "ui", bold = true }, ", each changing the panel's state: ", { text = "ui's design", link = "https://github.com/omerfuyar/OpenECS-std/blob/dev/DESIGN.md" } },
          { id = "about", color = "textDim", onLink = set("link") }),
        ui.tree(NODES,
          {
            id = "tree",
            height = 110,
            grow = 0,
            border = "tabShown",
            open = state.open,
            selected = state.node,
            onSelect = set("node"),
            onToggle = function(id, open)
              state.open[id] = open or nil
            end
          }),
      }) or ui.group({ title = "Options", gap = 8 }, {
        ui.toggle(state.sound, { id = "sound", label = "Sound", onChange = set("sound") }),
        ui.toggle(state.dark, { id = "dark", label = "Dark", look = "switch", onChange = set("dark") }),
        ui.row({ style = LABELED },
          { ui.text("Volume"), ui.slider(state.volume,
            { id = "volume", step = 0.1, grow = 1, onChange = set("volume") }) }),
        ui.row({ style = LABELED },
          { ui.text("Size"), ui.selector(state.size, SIZES, { id = "size", onSelect = set("size") }) }),
        ui.row({ style = LABELED },
          { ui.text("Fruit"), ui.dropdown(state.fruit, FRUITS, { id = "fruit", onSelect = set("fruit") }) }),
        -- a number field takes a number from min to max: Return gives what is typed to onSubmit, and Up and Down change it by step;
        -- onChange would get the number at each edit
        ui.row({ style = LABELED },
          { ui.text("Count"), ui.number(state.count,
            { id = "count", min = 0, max = 10, step = 1, grow = 1, onSubmit = set("count") }) }),
      }),
      ui.list(
        {
          id = "list",
          height = 90,
          grow = 0,
          border = "tabShown",
          selected = state.selected,
          onSelect = set(
            "selected")
        },
        items),
      -- a field keeps what is typed while it has the keys; Left, Right, Home and End move its cursor, Shift with them selects, and Ctrl+C, Ctrl+X and Ctrl+V copy, cut and paste
      ui.row({ style = LABELED }, { ui.text("Name"), ui.field(state.name, { id = "name", grow = 1, onChange = set("name") }) }),
      -- text with wrap = true breaks into lines at the width of its column
      ui.text(
        "Tab gives the keys to the next control and Shift+Tab to the one before. Return or Space presses the control that has them, " ..
        "Left and Right change a selector or a slider, and Escape takes the keys away. A field takes typing as soon as it has the keys. " ..
        "In a field, Home and End move the cursor to its start and end, Shift with them selects, and Ctrl+C, Ctrl+X and Ctrl+V copy, cut and paste.",
        { id = "note", style = "note", wrap = true }),
    }))

    -- the rectangles of the elements, in the panel's surface pixels; ui.rect gives nil for an element that is not shown, such as one on another tab
    for _, id in ipairs(IDS) do
      local rect = ui.rect(state.panel, id)
      state.rects[id] = rect and {
        x = rect.x * surface.scale,
        y = rect.y * surface.scale,
        width = rect.width * surface.scale,
        height = rect.height * surface.scale,
      }
    end
  end,

  -- the panel's events go to ui, which calls the callbacks of the elements they reach; Up and Down choose a list's or the tree's next item and
  -- the one before, and Right and Left open and close the tree's chosen node
  event = function(state, event)
    ui.event(state.panel, event)
  end,

  destroy = function(state)
    ui.forget(state.panel)
  end,

  -- the values and the rectangles are saved, so the test can read them
  saveState = function(state)
    return {
      clicks = state.clicks,
      sound = state.sound,
      volume = state.volume,
      size = SIZES[state.size],
      fruit = FRUITS[state.fruit],
      count = state.count,
      tab = TABS[state.tab],
      tip = ui.tooltip(state.panel),
      inspected = ui.inspected(state.panel),
      selected = state.selected,
      name = state.name,
      node = state.node,
      open = state.open,
      sort = state.sort,
      ascending = state.ascending,
      row = state.row,
      first = TABS[state.tab] == "Table" and sorted(state)[1].name or nil,
      link = state.link,
      rects = state.rects
    }
  end,
})
