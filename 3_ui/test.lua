-- each control changes the panel's state: clicks on the button count, and clicks beside it do not

return {
  preset = "preset.lua",
  run = function(test)
    local panel = test.rect(1)

    -- the state of the panel, and the middle of an element in the window
    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    local function at(id, across, down)
      local rect = state().rects[id]
      return panel.x + rect.x + rect.width * (across or 0.5), panel.y + rect.y + rect.height * (down or 0.5)
    end

    test.click(at("button"))
    test.click(at("button"))
    test.click(panel.x + 5, panel.y + 5)
    test.match(test.panel(1), { title = "Controls (2)" })

    test.click(at("sound", 0.05))
    test.match(state().sound, true, "the toggle")

    -- the knob is dragged from the middle to the right end
    local x, y = at("volume")
    local right = at("volume", 1)
    test.drag(x, y, right + 20, y)
    test.match(state().volume, 1.0, "the slider")

    test.click(at("size", 5 / 6))
    test.match(state().size, "L", "the selector")

    -- the dropdown opens its choices in a popup, one row each
    test.click(at("fruit"))
    local menu = test.popup(1)
    test.click(menu.x + 10, menu.y + menu.height * 2.5 / 3)
    test.match(state().fruit, "Cherry", "the dropdown")

    test.click(at("item:2"))
    test.match(state().selected, 2, "the list")
  end,
}
