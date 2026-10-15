-- A panel of controls built with the ui standard plugin: a button that counts its clicks, and the other elements ui offers.
-- A standard plugin ships with OpenECS for other plugins to build on: draw draws shapes and text, and ui builds user interfaces on it.

local ecs = require("ecs")

-- require with a plugin's name gives that plugin's functions; the manifest must depend on it, so it loads first
-- editors complete them from the definitions that the build writes, which .luarc.json names (README.md, "Editors")
local ui = require("ui")

local FRUITS = { "Apple", "Banana", "Cherry" }
local SIZES = { "S", "M", "L" }
local ITEMS = { "First item", "Second item", "Third item" }

-- the elements the test clicks, by id; their rectangles are saved, so the test finds them
local IDS = { "button", "tab", "sound", "volume", "size", "fruit", "count", "item:2", "name", "note" }

ecs.panel.registerType({
  name = "panel",
  title = "Controls",

  create = function(panel)
    return { panel = panel, clicks = 0, sound = false, dark = true, volume = 0.5, size = "M", fruit = "Apple", count = 3, tab = "Options", selected = 1, name = "", rects = {} }
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
      ui.tabs(controls.tab, { "Options", "About" }, { id = "tab", onChange = set("tab") }),
      controls.tab == "About" and ui.text("The controls of ui, each changing the panel's state.", { color = "textDim" }) or ui.group({ title = "Options", gap = 8 }, {
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
  event = function(controls, event)
    ui.event(controls.panel, event)
  end,

  destroy = function(controls)
    ui.forget(controls.panel)
  end,

  -- the values and the rectangles are saved, so the test can read them
  saveState = function(controls)
    return { clicks = controls.clicks, sound = controls.sound, volume = controls.volume, size = controls.size, fruit = controls.fruit, count = controls.count, tab = controls.tab, tip = ui.tip(controls.panel), selected = controls.selected, name = controls.name, rects = controls.rects }
  end,
})
