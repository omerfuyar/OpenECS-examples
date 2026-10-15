-- the controls in C, on workspace 2, change the panel's state as the ones in Lua do: ui's macros take what each element got at the next draw

return {
  preset = "preset.lua",
  run = function(test)
    test.call("ecs.workspace.switch2")
    local panel = test.rect(2)

    local function state()
      return test.session().workspaces[2].windows[1].panels[1].state
    end

    local function at(id, across)
      local rect = state().rects[id]
      return panel.x + rect.x + rect.width * (across or 0.5), panel.y + rect.y + rect.height / 2
    end

    -- UI_BUTTON gives true once for each click
    test.click(at("button"))
    test.click(at("button"))
    test.match(state().clicks, 2, "the clicks")
    test.match(test.panel(2), { title = "Controls in C (2)" })

    -- UI_TOGGLE, UI_SLIDER and UI_SELECTOR write what changed into the plugin's variables
    test.click(at("sound", 0.05))
    test.match(state().sound, true, "the toggle")

    local x, y = at("volume")
    test.drag(x, y, at("volume", 1) + 20, y)
    test.match(state().volume, 1.0, "the slider")

    test.click(at("size", 5 / 6))
    test.match(state().size, "L", "the selector")

    -- UI_LIST writes the chosen item's number
    test.click(at("item:2"))
    test.match(state().selected, 2, "the list")

    -- UI_FIELD copies each edit into the plugin's buffer
    test.click(at("name"))
    test.text("Ada")
    test.match(state().name, "Ada", "the field")
  end,
}
