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

    -- Shift with a move selects, and typing replaces the selection; Ctrl moves by words
    test.key("Shift+End")
    test.text("Y")
    test.match(state().name, "Y", "the selection replaced")
    test.text("ab cd")
    test.key("Ctrl+Left")
    test.key("Ctrl+Shift+Right")
    test.key("Ctrl+X")
    test.match(state().name, "Yab ", "the word cut")
    test.key("Home")
    test.key("Ctrl+V")
    test.match(state().name, "cdYab ", "the word pasted")

    -- Ctrl+A selects all, and Backspace deletes the selection
    test.key("Ctrl+A")
    test.key("Backspace")
    test.match(state().name, "", "the field emptied")

    -- a drag across the field selects what it passes over
    test.text("drag")
    local fromX, fromY = at("name", 0.01)
    local toX = at("name", 0.99)
    test.drag(fromX, fromY, toX, fromY)
    test.text("Z")
    test.match(state().name, "Z", "the dragged selection replaced")

    -- the note wraps into more than one line
    test.match(state().rects.note.height > state().rects.name.height, true, "the wrapped text")

    -- Escape stops typing; the field is the last control, so Tab goes round to the first, the button, which Space presses
    test.key("Escape")
    test.key("Tab")
    test.key("Space")
    test.match(state().clicks, 3, "the keys")

    -- the About tab holds a tree; a click on a node's arrow opens it, and a click beside the arrow chooses the node
    test.click(at("tab", 0.02))
    test.key("Right")
    test.match(state().tab, "About", "the tab of the tree")
    local _, srcY = at("tree:src")
    test.click(panel.x + state().rects["tree:src"].x + 14, srcY)
    test.match(state().open, { src = true }, "the opened node")
    test.click(at("tree:lib"))
    test.match(state().node, "lib", "the chosen node")

    -- Right opens the chosen node, then chooses its first child; Left on a node without children chooses its parent, then closes it
    test.key("Right")
    test.match(state().open, { src = true, lib = true }, "the node opened with Right")
    test.key("Right")
    test.match(state().node, "util", "the first child, after Right on an open node")
    test.key("Left")
    test.match(state().node, "lib", "the parent")
    test.key("Left")
    test.match(state().open, { src = true }, "the node closed with Left")
    test.key("Down")
    test.match(state().node, "readme", "the node below the closed one")

    -- the Table tab: the rows are sorted by name, a click on a title sorts by its column, and a second click reverses the order
    test.click(at("tab", 0.02))
    test.key("Right")
    test.key("Right")
    test.match(state().tab, "Table", "the tab of the table")
    test.match(state().first, "Apple", "the first row by name")
    local header, row = state().rects["table:header"], state().rects["table:1"]
    test.match(header.x, row.x, "the header over the rows")
    test.click(at("table:title:name"))
    test.match({ state().sort, state().ascending }, { "name", false }, "the order reversed")
    test.match(state().first, "Cherry", "the first row, names reversed")
    test.click(at("table:title:price"))
    test.match({ state().sort, state().ascending, state().first }, { "price", true, "Banana" }, "the rows by price")

    -- a click on a row chooses it
    test.click(at("table:2"))
    test.match(state().row, 2, "the chosen row")
  end,
}
