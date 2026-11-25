-- the checks of the controls, which the Lua plugin and the C plugin pass alike: each control changes the panel's state, clicks on the button count, and clicks
-- beside it do not; number is the panel's and its workspace's number, and title the panel's title before the clicks are counted in it

return function(test, number, title)
  local panel = test.rect(number)

  -- the state of the panel, and the middle of an element in the window
  local function state()
    return test.session().workspaces[number].windows[1].panels[1].state
  end

  local function at(id, across, down)
    local rect = state().rects[id]
    return panel.x + rect.x + rect.width * (across or 0.5), panel.y + rect.y + rect.height * (down or 0.5)
  end

  test.click(at("button"))
  test.click(at("button"))
  test.click(panel.x + 5, panel.y + 5)
  test.match(test.panel(number), { title = title .. " (2)" })

  -- the button's tooltip shows in a popup when the pointer rests on it, and goes when the pointer leaves
  test.move(at("button"))
  test.wait(0.8)
  test.match(state().tip, "button", "the tooltip")
  test.match((pcall(test.popup, 1)), true, "the tooltip's popup")
  test.move(panel.x + 5, panel.y + 5)
  test.match(state().tip, nil, "the tooltip gone")
  test.match((pcall(test.popup, 1)), false, "the tooltip's popup closed")

  -- the pointer goes through a tooltip, so a click on the button counts while its tooltip shows, and hides the tooltip
  test.move(at("button"))
  test.wait(0.8)
  test.click(at("button"))
  test.match(state().clicks, 3, "a click while the tooltip shows")
  test.match(state().tip, nil, "the tooltip gone at a click")

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
  test.match(state().kept, 1.0, "the slider's release")

  -- while the left button drags the knob, a click of the middle button leaves the drag to the left one: the knob follows the pointer out of the
  -- panel, and only the left button's release ends the drag
  test.press(x, y)
  test.click(x, y, 2)
  test.move(panel.x - 20, y)
  test.match(state().kept, 1.0, "the slider kept while its drag goes on")
  test.release(panel.x - 20, y)
  test.match({ state().volume, state().kept }, { 0.0, 0.0 }, "the slider dragged while another button is clicked")

  test.click(at("size", 5 / 6))
  test.match(state().size, "L", "the selector")

  -- the dropdown opens its choices in a popup, one row each
  test.click(at("fruit"))
  local menu = test.popup(1)
  test.click(menu.x + 10, menu.y + menu.height * 2.5 / 3)
  test.match(state().fruit, "Cherry", "the dropdown")
  -- typing in it shows only the choices that hold the text, and Return chooses the first of them
  test.click(at("fruit"))
  test.key("A")
  test.key("N")
  test.key("Return")
  test.match(state().fruit, "Banana", "the dropdown's search")

  -- a dropdown of more choices than the window holds shows no more than its room, inside the window, and scrolls: the wheel moves
  -- it three rows on, so its first row is the fourth choice; Down past the last row shown scrolls too
  local box = panel
  test.click(at("item"))
  local long = test.popup(1)
  local row = long.height / math.floor(long.height / (menu.height / 3) + 0.5)
  test.match({ long.y >= 0, long.y + long.height <= box.y + box.height, long.height < 40 * row }, { true, true, true },
    "the long dropdown keeps inside the window")
  test.wheel(long.x + 10, long.y + 10, -1)
  test.click(long.x + 10, long.y + row / 2)
  test.match(state().item, "Item 4", "the wheel scrolls the long dropdown")
  test.click(at("item"))
  for _ = 1, 39 do
    test.key("Down")
  end
  test.key("Return")
  test.match(state().item, "Item 40", "Down scrolls to the last choice")

  -- the number field keeps its number from 0 to 10; Up and Down change it by 1, a text that is not a number is not taken, and a sum is
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
  -- a sum gives its result
  test.click(at("count"))
  test.key("Ctrl+A")
  test.text("2*3+1")
  test.key("Return")
  test.match(state().count, 7, "the number, from a sum")

  -- a drag sideways on the number changes it by a step each unit, kept from 0 to 10, and a tenth of that with Shift
  local x, y = at("count")
  test.drag(x, y, x - 40, y)
  test.match(state().count, 0, "a drag to the left, down to the least")
  test.drag(x, y, x + 100, y)
  test.match(state().count, 10, "a drag to the right, up to the most")
  test.drag(x, y, x - 20, y, "Shift")
  test.match(state().count, 8, "a drag with Shift, by a tenth of the steps")

  -- the colour element opens a picker in a popup; a press in its square gives the colour there, more saturated and brighter to the top right,
  -- and Return closes it
  test.click(at("tint"))
  local picker = test.popup(1)
  test.click(picker.x + picker.width * 0.75, picker.y + picker.height * 0.1)
  test.key("Return")
  test.match(#state().tint == 7 and state().tint ~= "#3366CC", true, "the picked colour")

  -- the picker works from the keys too: the arrows move saturation and value, and Shift with Up and Down the hue; each move gives the colour
  test.click(at("tint"))
  local picked = state().tint
  test.key("Left")
  test.match(state().tint ~= picked, true, "the colour that Left gives")
  picked = state().tint
  test.key("Shift+Down")
  test.match(state().tint ~= picked, true, "the colour that Shift+Down gives")
  test.key("Return")

  -- a click on the section's heading hides what is below it
  test.click(at("colors:heading"))
  test.match({ state().colors, state().rects.tint }, { false, nil }, "the closed section")

  test.click(at("item:2"))
  test.match(state().selected, 2, "the list")

  -- the click gave the list the keys, so Down chooses the next item; a list is one stop of Tab, which leaves it and comes back to it
  test.key("Down")
  test.match(state().selected, 3, "the item below")
  test.key("Tab")
  test.key("Shift+Tab")
  test.key("Up")
  test.match(state().selected, 2, "the item above, after Tab and Shift+Tab")

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
  local fromX, fromY = at("name", 0)
  fromX = fromX + 4 -- before the first letter, however wide the field is
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
  test.match(state().clicks, 4, "the keys")

  -- a path is typed as a field is, and Return gives it; its button would open the file dialog
  test.click(at("file", 0.1))
  test.text("plugin.lua")
  test.key("Return")
  test.match(state().file, "plugin.lua", "the path")

  -- the About tab holds a tree; a click on a node's arrow opens it, and a click beside the arrow chooses the node
  test.click(at("tab", 0.02))
  test.key("Right")
  test.match(state().tab, "About", "the tab of the tree")

  -- the About tab's text ends with a link, which a click gives to the panel
  test.click(at("about", 0.95))
  test.match(state().link, "https://github.com/omerfuyar/OpenECS-std/blob/dev/DESIGN.md", "the clicked link")
  -- the tags' row wraps in its narrow column: the first two share a line, and the last is on a line below
  local tags = state().rects
  test.match({ tags["tag:2"].y == tags["tag:1"].y, tags["tag:6"].y > tags["tag:1"].y }, { true, true }, "the wrapped row")
  -- a text with maxLines = 2 takes two lines, as a text of two lines does, however long it is; the last ends with an ellipsis, which makes
  -- it wider than the same lines without one
  local lines = state().rects.lines
  test.match({ tags.cut.height, tags.cutLines.height, tags.cutSpans.height }, { lines.height, lines.height, lines.height }, "the texts cut to two lines")
  test.match({ tags.cutLines.width > lines.width, tags.cutSpans.width > lines.width }, { true, true }, "the ellipsis of the cut texts")
  local _, srcY = at("tree:src")
  test.click(panel.x + state().rects["tree:src"].x + 14, srcY)
  test.match(state().open, { src = true }, "the opened node")
  test.click(at("tree:lib"))
  test.match(state().node, "lib", "the chosen node")

  -- Left and Right go through the parts of the chosen node's row, its arrow and its marks, and Space presses the part: Right reaches lib's
  -- arrow and Space opens the node; the ring keeps its place in the row as Up and Down choose other nodes
  test.key("Right")
  test.key("Space")
  test.match(state().open, { src = true, lib = true }, "the node opened with Space on its arrow")
  -- lib holds a hundred files, so the tree builds only the rows in view and near it: End brings the last into view, and builds it then
  test.match(state().rects["tree:f100"], nil, "a long tree builds the rows in view")
  test.key("End")
  test.match(state().rects["tree:f100"] ~= nil, true, "a long tree builds the rows that come into view")
  test.key("Home")
  test.key("Down")
  test.match(state().node, "util", "the first child")
  test.key("Up")
  test.key("Space")
  test.match(state().open, { src = true }, "the node closed with Space on its arrow")
  test.key("Down")
  test.match(state().node, "readme", "the node below the closed one")

  -- README.md has no arrow, so its first part is its mark, which Space turns on; Left goes back to the node itself, where Space does nothing
  test.key("Space")
  test.match(state().starred, true, "Space on the mark")
  test.key("Left")
  test.key("Space")
  test.match(state().starred, true, "Space on the node itself")
  test.key("Right")
  test.key("Space")
  test.match(state().starred, false, "Space on the mark again")

  -- README.md's mark, at the end of its row, turns on and off with a click, and keeps the chosen node
  test.click(at("tree:main"))
  test.click(at("tree:readme:star"))
  test.match({ state().starred, state().node }, { true, "main" }, "a click turns a mark on, and chooses no node")
  test.click(at("tree:readme:star"))
  test.match(state().starred, false, "and another turns it off")
  -- its second mark is an icon, a padlock, as wide as it is high: a click locks the file and leaves the star, and another opens it
  local lock = state().rects["tree:readme:lock"]
  test.match(lock ~= nil and lock.width <= lock.height + 1, true, "an icon mark is a square")
  test.click(at("tree:readme:lock"))
  test.match({ state().locked, state().starred, state().node }, { true, false, "main" }, "a click on the icon locks the file")
  test.click(at("tree:readme:lock"))
  test.match(state().locked, false, "and another opens it")
  -- each icon is a square a line of text high
  for _, name in ipairs({ "eye", "eyeClosed", "lock", "lockOpen" }) do
    local icon = state().rects["icon:" .. name]
    test.match(icon ~= nil and math.abs(icon.width - icon.height) <= 1 and icon.height > 8, true, "the icon " .. name)
  end
  -- a button's label of an icon and words is wider than the words by the icon, and its click locks the file, as the mark's does
  local button = state().rects.lockButton
  test.match(button ~= nil and button.width > button.height * 2, true, "a label of an icon and words")
  test.click(at("lockButton"))
  test.match(state().locked, true, "the button with an icon locks the file")
  test.click(at("lockButton"))
  test.match(state().locked, false, "and unlocks it")

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
end
