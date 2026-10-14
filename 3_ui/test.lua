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

    -- the button's tooltip shows when the pointer rests on it, and goes when the pointer leaves
    test.move(at("button"))
    test.wait(0.8)
    test.match(state().tip, "button", "the tooltip")
    test.move(panel.x + 5, panel.y + 5)
    test.match(state().tip, nil, "the tooltip gone")

    -- a click on the first tab gives the tabs the keys, and Right and Left choose the next and the one before
    test.click(at("tab", 0.02))
    test.key("Right")
    test.match(state().tab, "About", "the second tab")
    test.key("Left")
    test.match(state().tab, "Options", "the first tab")

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

    -- the number field keeps its number from 0 to 10; Up and Down change it by 1, and a text that is not a number is not taken
    test.click(at("count"))
    test.text("7")
    test.key("Return")
    test.match(state().count, 10, "the number, kept to its maximum")
    test.click(at("count"))
    test.key("Down")
    test.match(state().count, 9, "the number, one step down")
    test.text("x")
    test.key("Return")
    test.key("Escape")
    test.match(state().count, 9, "the number, after a text that is not one")

    test.click(at("item:2"))
    test.match(state().selected, 2, "the list")

    -- typing goes in at the cursor, which the arrows move
    test.click(at("name"))
    test.text("abc")
    test.key("Left")
    test.key("Left")
    test.text("X")
    test.key("Home")
    test.key("Delete")
    test.match(state().name, "Xbc", "the field")

    -- the note wraps into more than one line
    test.match(state().rects.note.height > state().rects.name.height, true, "the wrapped text")

    -- Escape stops typing; the field is the last control, so Tab goes round to the first, the button, which Space presses
    test.key("Escape")
    test.key("Tab")
    test.key("Space")
    test.match(state().clicks, 3, "the keys")
  end,
}
