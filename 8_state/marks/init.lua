-- Panels that keep the dots clicked on them. Sessions save each panel's dots, and the plugin's count of every dot placed.
-- A session is a tool as it was left: OpenECS saves it when the tool quits and builds the tool from it next time.

local ecs = require("ecs")

local draw = require("draw") -- the functions of a plugin the manifest depends on

-- raise it when the saved state changes shape; create then gets the old version, and can read or drop the old state
local STATE_VERSION = 1
local DOT = 8 -- in layout units

local placed = 0 -- every dot placed, in every session; the plugin's own state

ecs.panel.registerType({
  name = "panel",
  title = "Marks",
  stateVersion = STATE_VERSION,

  -- saved is the state saveState gave last time, or nil for a new panel
  create = function(panel, saved, version)
    local marks = { panel = panel, dots = {}, scale = 1 }

    if version == STATE_VERSION and saved then
      marks.dots = saved.dots
    end

    return marks
  end,

  draw = function(state, surface)
    state.scale = surface.scale
    surface:fill(0, 0, surface.width, surface.height, "background")

    for i = 1, #state.dots - 1, 2 do
      draw.fill(surface, state.dots[i] - DOT / 2, state.dots[i + 1] - DOT / 2, DOT, DOT, "accent")
    end
  end,

  event = function(state, event)
    if event.type == "pointerDown" and event.button == 1 then
      table.insert(state.dots, event.x / state.scale) -- dots are kept in layout units, so they stay put at any scale
      table.insert(state.dots, event.y / state.scale)
      placed = placed + 1
      state.panel.unsaved = true -- marks the tab; closing the panel then asks to save
      state.panel:redraw()
    end
  end,

  -- gives what the session keeps: plain values only, such as numbers, strings and tables of them
  saveState = function(state)
    return { dots = state.dots }
  end,

  -- saves the panel's unsaved work, when the user asks or closes it; the dots are already in the session, so it only clears the mark
  save = function(state)
    state.panel.unsaved = false
    return true
  end,
})

-- state that belongs to no panel, but to the plugin; restoreState runs before the session's panels are made
ecs.plugin.register({
  stateVersion = 1,
  saveState = function()
    return { placed = placed }
  end,
  restoreState = function(saved)
    placed = saved and saved.placed or 0
  end,
})
