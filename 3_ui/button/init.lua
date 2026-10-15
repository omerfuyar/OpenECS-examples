-- A panel of controls built with the ui standard plugin: a button that counts its clicks, and the other elements ui offers.
-- A standard plugin ships with OpenECS for other plugins to build on: draw draws shapes and text, and ui builds user interfaces on it.

local ecs = require("ecs")

-- require with a plugin's name gives that plugin's functions; the manifest must depend on it, so it loads first
-- editors complete them from the definitions that the build writes, which .luarc.json names (README.md, "Editors")
local ui = require("ui")

local FRUITS = { "Apple", "Banana", "Cherry" }
local SIZES = { "S", "M", "L" }
local ITEMS = { "First item", "Second item", "Third item" }

-- the Table tab's columns and rows; the panel sorts the rows, and the table shows them in its order
local COLUMNS = { { id = "name", title = "Fruit" }, { id = "price", title = "Price" }, { id = "stock", title = "In stock" } }
local FRUIT_ROWS = { { name = "Cherry", price = 4.5, stock = 12 }, { name = "Apple", price = 1.2, stock = 40 }, { name = "Banana", price = 0.8, stock = 25 } }

-- the nodes of the About tab's tree; a node with children opens and closes
local NODES = {
  { id = "src", label = "src", children = {
    { id = "main", label = "main.c" },
    { id = "lib", label = "lib", children = { { id = "util", label = "util.c" } } },
  } },
  { id = "readme", label = "README.md" },
}

-- the elements the test clicks, by id; their rectangles are saved, so the test finds them
local IDS = { "button", "tab", "sound", "volume", "size", "fruit", "count", "item:2", "name", "note", "tree:src", "tree:lib", "table:header", "table:1", "table:2", "table:title:name", "table:title:price" }

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

ecs.panel.registerType({
  name = "panel",
  title = "Controls",

  create = function(panel)
    return { panel = panel, clicks = 0, sound = false, dark = true, volume = 0.5, size = "M", fruit = "Apple", count = 3, tab = "Options", selected = 1, name = "", node = "readme", open = {}, sort = "name", ascending = true, row = nil, rects = {} }
  end,

  -- draw runs only when the panel needs drawing; a panel type that draws every frame says continuous = true
  -- ui lays out and draws the elements that draw describes each time, so the panel keeps only its own state
  draw = function(controls, surface)
    -- each callback changes the panel's state; ui then asks the core to draw the panel again
    local function set(key)
      return function(value)
        controls[key] = value
      end
    end

    local items = {}

    for i, text in ipairs(ITEMS) do
      items[i] = ui.text(text, { id = "item:" .. i })
    end

    ui.show(controls.panel, surface, ui.column({ padding = 24, gap = 12 }, {
      ui.text(("Clicked %d times"):format(controls.clicks), { size = 18 }),
      -- a tooltip shows when the pointer rests on its element
      ui.button("Click me", {
        id = "button",
        tooltip = "Counts the clicks in the panel's title",
        onClick = function()
          controls.clicks = controls.clicks + 1
          controls.panel.title = ("Controls (%d)"):format(controls.clicks)
        end,
      }),
      ui.separator(),
      -- tabs choose what shows below them; the panel keeps the chosen one and describes only its elements
      ui.tabs(controls.tab, { "Options", "About", "Table" }, { id = "tab", onChange = set("tab") }),
      -- a table lines its cells up below its columns' titles; a click on a title sorts by that column, and a second one reverses the order
      controls.tab == "Table" and ui.table({ id = "table", height = 110, grow = 0, stretch = true, border = "tabShown", sort = controls.sort, ascending = controls.ascending,
        selected = controls.row, onSelect = set("row"),
        onSort = function(column)
          controls.ascending = column ~= controls.sort or not controls.ascending
          controls.sort, controls.row = column, nil
        end }, COLUMNS, sorted(controls)) or
      -- a tree shows its open nodes' children below them; the panel keeps which nodes are open, and the chosen one
      controls.tab == "About" and ui.column({ gap = 8 }, {
        ui.text("The controls of ui, each changing the panel's state.", { color = "textDim" }),
        ui.tree({ id = "tree", height = 110, grow = 0, border = "tabShown", open = controls.open, selected = controls.node, onSelect = set("node"),
          onToggle = function(id, open)
            controls.open[id] = open or nil
          end }, NODES),
      }) or ui.group({ title = "Options", gap = 8 }, {
        ui.toggle(controls.sound, { id = "sound", label = "Sound", onChange = set("sound") }),
        ui.toggle(controls.dark, { id = "dark", label = "Dark", look = "switch", onChange = set("dark") }),
        ui.row({ gap = 8 }, { ui.text("Volume"), ui.slider(controls.volume, { id = "volume", step = 0.1, grow = 1, onChange = set("volume") }) }),
        ui.row({ gap = 8 }, { ui.text("Size"), ui.selector(controls.size, SIZES, { id = "size", onChange = set("size") }) }),
        ui.row({ gap = 8 }, { ui.text("Fruit"), ui.dropdown(controls.fruit, FRUITS, { id = "fruit", onChange = set("fruit") }) }),
        -- a number field takes a number from min to max: Return gives what is typed, and Up and Down change it by step
        ui.row({ gap = 8 }, { ui.text("Count"), ui.number(controls.count, { id = "count", min = 0, max = 10, step = 1, grow = 1, onChange = set("count") }) }),
      }),
      ui.list({ id = "list", height = 90, grow = 0, border = "tabShown", selected = controls.selected, onSelect = set("selected") }, items),
      -- a field keeps what is typed while it has the keys; Left, Right, Home and End move its cursor, Shift with them selects, and Ctrl+C, Ctrl+X and Ctrl+V copy, cut and paste
      ui.row({ gap = 8 }, { ui.text("Name"), ui.field(controls.name, { id = "name", grow = 1, onChange = set("name") }) }),
      -- text with wrap = true breaks into lines at the width of its column
      ui.text("Tab gives the keys to the next control and Shift+Tab to the one before. Return or Space presses the control that has them, " ..
        "Left and Right change a selector or a slider, and Escape takes the keys away. A field takes typing as soon as it has the keys.",
        { id = "note", wrap = true, color = "textDim" }),
    }))

    -- the rectangles of the elements, in the panel's surface pixels
    for _, id in ipairs(IDS) do
      local _, x, y, width, height = ui.rect(controls.panel, id)
      controls.rects[id] = { x = x * surface.scale, y = y * surface.scale, width = width * surface.scale, height = height * surface.scale }
    end
  end,

  -- the panel's events go to ui, which calls the callbacks of the elements they reach
  -- Up and Down choose the tree's next node and the one before, and Right and Left open and close the chosen one, when no element takes them
  event = function(controls, event)
    if ui.event(controls.panel, event) or event.type ~= "keyDown" or controls.tab ~= "About" then
      return
    end

    if event.key == "Up" or event.key == "Down" then
      ui.move(controls.panel, "tree", event.key == "Up" and -1 or 1)
    elseif event.key == "Left" or event.key == "Right" then
      ui.expand(controls.panel, "tree", event.key == "Right")
    end
  end,

  destroy = function(controls)
    ui.forget(controls.panel)
  end,

  -- the values and the rectangles are saved, so the test can read them
  saveState = function(controls)
    return { clicks = controls.clicks, sound = controls.sound, volume = controls.volume, size = controls.size, fruit = controls.fruit, count = controls.count, tab = controls.tab, tip = ui.tip(controls.panel), selected = controls.selected, name = controls.name, node = controls.node, open = controls.open, sort = controls.sort, ascending = controls.ascending, row = controls.row,
      first = controls.tab == "Table" and sorted(controls)[1].name or nil, rects = controls.rects }
  end,
})
