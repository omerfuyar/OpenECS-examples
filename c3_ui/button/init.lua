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
local SIZES = { "S", "M", "L" }
local TABS = { "Options", "About", "Table" }
local ITEMS = { "First item", "Second item", "Third item" }
local TAGS = { "Lua", "C", "SDL", "Clay", "libffi", "stb" }

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
  "tree:lib", "table:header", "table:1", "table:2", "table:title:name", "table:title:price", "about",
  "tint", "colors:heading", "tag:1", "tag:2", "tag:6", "file" }

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
  kept = 0.5,
  size = 2,
  fruit = 1,
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

ecs.panel.registerType({
  name = "panel",
  title = "Controls",

  create = function(panel)
    local controls = copy(START)
    controls.panel = panel
    -- the panel takes the tree's nodes that are dragged onto it, as data of the core's drag and drop
    panel:acceptDrops({ "example.node" })
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

    local items, tags = {}, {}

    for i, text in ipairs(TAGS) do
      tags[i] = ui.button(text, { id = "tag:" .. i })
    end

    for i, text in ipairs(ITEMS) do
      items[i] = ui.text(text, { id = "item:" .. i })
    end

    -- a right click that no other element takes reaches the root's onMenu, which opens a menu there, in layout units as ui.menu takes them
    local function menu(x, y)
      ui.menu(state.panel, x, y, {
        { label = "Add a click", onClick = function() state.clicks = state.clicks + 1 end },
        { line = true },
        { label = "Reset the clicks", enabled = state.clicks > 0, onClick = function() state.clicks = 0 end },
      })
    end

    ui.show(state.panel, surface, ui.column({ style = STYLES.view, onMenu = menu }, {
      ui.text(("Clicked %d times"):format(state.clicks), { style = STYLES.title }),
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
            -- the tree chooses many nodes: selected is the list of the chosen ones, and the first is where Up and Down move from;
            -- a press with Ctrl adds a node or takes it out, and one with Shift chooses the shown nodes from the first chosen one to it
            selected = state.nodes,
            onSelect = function(id, how, between)
              if how == "toggle" then
                local kept = {}

                for _, other in ipairs(state.nodes) do
                  if other ~= id then
                    kept[#kept + 1] = other
                  end
                end

                if #kept == #state.nodes then
                  kept[#kept + 1] = id
                end

                state.nodes = kept
              elseif how == "range" then
                state.nodes = between
              else
                state.nodes = { id }
              end

              state.node = state.nodes[1]
            end,
            onToggle = function(id, open)
              state.open[id] = open or nil
            end,
            -- a right click on a node chooses it, unless it is chosen, and gives its id, as a menu about it would take it
            onMenu = function(id)
              state.menuNode = id
            end,
            -- a press on a node and a move of the pointer drag what onDrag gives, as data of the core's drag and drop
            onDrag = function(id)
              return "example.node", id
            end,
            -- a node dropped on the tree gives the node it landed on, and where: before it, into it, or after it, by where on its row
            onDrop = function(id, where, _, value)
              state.dropped = { node = value, where = where, on = id }
            end,
          }),
        -- a row with wrap = true puts the children that do not fit the rest of a line on the next line, as a toolbar does in a narrow panel;
        -- this one is in a narrow column, so its buttons take two lines
        ui.column({ width = 160 }, { ui.row({ wrap = true, gap = 4 }, tags) }),
      }) or ui.group({ title = "Options", gap = 8 }, {
        ui.toggle(state.sound, { id = "sound", label = "Sound", onChange = set("sound") }),
        ui.toggle(state.dark, { id = "dark", label = "Dark", look = "switch", onChange = set("dark") }),
        ui.row({ style = LABELED },
          { ui.text("Volume"), ui.slider(state.volume,
            -- onChange would get each value of a drag; onSubmit gets the one that its release ends on, which a tool keeps as one change,
            -- and the slider shows the dragged value until then
            { id = "volume", step = 0.1, grow = 1, onSubmit = function(value)
              state.volume, state.kept = value, value
            end }) }),
        ui.row({ style = LABELED },
          { ui.text("Size"), ui.selector(state.size, SIZES, { id = "size", onSelect = set("size") }) }),
        ui.row({ style = LABELED },
          { ui.text("Fruit"), ui.dropdown(state.fruit, FRUITS, { id = "fruit", onSelect = set("fruit") }) }),
        -- a number field takes a number from min to max: Return gives what is typed to onSubmit, and Up and Down change it by step;
        -- onChange would get the number at each edit
        ui.row({ style = LABELED },
          { ui.text("Count"), ui.number(state.count,
            { id = "count", min = 0, max = 10, step = 1, grow = 1, onSubmit = set("count") }) }),
        -- a section's heading shows and hides what is below it, at a click; the panel keeps whether it is open
        -- a colour element is a swatch, which a click opens in a picker; onChange gets the colour a press in the picker ends on
        ui.section("Colour", { id = "colors", open = state.colors, onToggle = set("colors") }, {
          ui.row({ style = LABELED }, { ui.text("Tint"), ui.color(state.tint, { id = "tint", onChange = set("tint") }) }),
        }),
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
      -- a path is a field with a button that opens the system's file dialog; the chosen file goes to onSubmit, as a typed path does at Return
      ui.row({ style = LABELED }, { ui.text("File"), ui.path(state.file, { id = "file", grow = 1, pattern = "lua", onSubmit = set("file") }) }),
      -- a field keeps what is typed while it has the keys; Left, Right, Home and End move its cursor, Shift with them selects, and Ctrl+C, Ctrl+X and Ctrl+V copy, cut and paste
      ui.row({ style = LABELED }, { ui.text("Name"), ui.field(state.name, { id = "name", grow = 1, placeholder = "Your name", onChange = set("name") }) }),
      -- text with wrap = true breaks into lines at the width of its column
      ui.text(
        "Tab gives the keys to the next control and Shift+Tab to the one before. Return or Space presses the control that has them, " ..
        "Left and Right change a selector or a slider, and Escape takes the keys away. A field takes typing as soon as it has the keys. " ..
        "In a field, Home and End move the cursor to its start and end, Shift with them selects, and Ctrl+C, Ctrl+X and Ctrl+V copy, cut and paste.",
        { id = "note", style = STYLES.note, wrap = true }),
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
      kept = state.kept,
      dropped = state.dropped,
      size = SIZES[state.size],
      fruit = FRUITS[state.fruit],
      count = state.count,
      tab = TABS[state.tab],
      tip = ui.tooltip(state.panel),
      inspected = ui.inspected(state.panel),
      selected = state.selected,
      name = state.name,
      file = state.file,
      node = state.node,
      nodes = state.nodes,
      menuNode = state.menuNode,
      open = state.open,
      sort = state.sort,
      ascending = state.ascending,
      row = state.row,
      first = TABS[state.tab] == "Table" and sorted(state)[1].name or nil,
      link = state.link,
      tint = state.tint,
      colors = state.colors,
      rects = state.rects
    }
  end,
})
