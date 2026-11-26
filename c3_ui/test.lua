-- the controls in Lua, on workspace 1: each control changes the panel's state, as the checks that the C plugin passes too say

local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset.lua",
  run = function(test)
    checks(test, 1, "Controls")

    -- the note beside a label breaks at nearly the column's width, so it takes about as many lines as the note alone, not twice as many
    local rects = test.session().workspaces[1].windows[1].panels[1].state.rects
    test.match(rects.beside.height < rects.note.height * 1.5, true, "wrapped text in a growing column of a row")

    -- in Lua, the tree chooses many nodes: Ctrl adds a node to the chosen ones or takes it out, and Shift chooses the shown nodes from the first
    -- chosen one to the pressed one
    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    local box = test.rect(1)
    local tabs = state().rects.tab
    test.click(box.x + tabs.x + tabs.width * 0.02, box.y + tabs.y + tabs.height / 2)
    test.key("Right")
    test.match(state().tab, "About", "the tab of the tree")

    -- the rows: src, its children main and lib, then readme, with src open and lib closed
    local src, lib = state().rects["tree:src"], state().rects["tree:lib"]
    local height = (lib.y - src.y) / 2
    local function row(i)
      return box.x + src.x + src.width * 0.6, box.y + src.y + src.height / 2 + height * (i - 1)
    end

    test.match(state().open, { src = true }, "src is open")
    -- a click with a modifier takes the place as two numbers, as row's two results are cut to one before another argument
    local x, y
    test.click(row(1))
    test.match(state().nodes, { "src" }, "a press chooses one node")
    x, y = row(3)
    test.click(x, y, nil, "Ctrl")
    test.match(state().nodes, { "src", "lib" }, "Ctrl adds a node")
    x, y = row(1)
    test.click(x, y, nil, "Ctrl")
    test.match(state().nodes, { "lib" }, "Ctrl takes a chosen node out")
    x, y = row(4)
    test.click(x, y, nil, "Shift")
    test.match(state().nodes, { "lib", "readme" }, "Shift chooses the nodes from the first chosen one")
    test.click(row(2))
    test.match(state().nodes, { "main" }, "a press alone chooses one again")
    x, y = row(4)
    test.click(x, y, 3)
    test.match(state().nodes, { "readme" }, "a right click chooses a node that is not chosen")
    test.match(state().menuNode, "readme", "and gives it to onMenu")

    -- a node dragged onto the middle of another's row drops into it, and onto the upper quarter of a row before it
    local toX, toY
    x, y = row(4)
    toX, toY = row(1)
    test.drag(x, y, toX, toY)
    test.match(state().dropped, { node = "readme", where = "into", on = "src" }, "a drop into a node")
    x, y = row(2)
    toX, toY = row(3)
    test.drag(x, y, toX, toY - height * 0.4)
    test.match(state().dropped, { node = "main", where = "before", on = "lib" }, "a drop before a node")

    -- a right click beside the elements reaches the root's onMenu, which opens the panel's menu there: its entries are a row each, with a line between the
    -- first and the second, and Reset is enabled only when there are clicks
    local clicks = state().clicks
    local corner = test.rect(1)
    test.click(corner.x + corner.width - 20, corner.y + corner.height - 20, 3)
    local menu = test.popup(1)
    test.click(menu.x + 10, menu.y + 10)
    test.match(state().clicks, clicks + 1, "the menu's first entry")
    -- the menu gives the core its entries, so test.menu reads them as it reads the core's menus; a line is not an entry
    test.click(corner.x + corner.width - 20, corner.y + corner.height - 20, 3)
    test.match(test.menu(), {
      { label = "Add a click", enabled = true, chosen = true },
      { label = "Reset the clicks", enabled = true, chosen = false },
      { label = "More", enabled = true, chosen = false },
    }, "the menu's entries")
    test.key("Down")
    test.match(test.menu()[2].chosen, true, "Down goes past the line to Reset")
    test.key("Return")
    test.match(state().clicks, 0, "Return runs Reset")
    -- More opens its entries in place, below the way back: Right opens it, Left goes back to More, Return opens it again, and Return
    -- runs its first entry
    test.click(corner.x + corner.width - 20, corner.y + corner.height - 20, 3)
    local whole = test.popup(1).height
    test.key("Up")
    test.key("Right")
    local more = test.popup(1).height
    test.match(test.menu(), { { label = "More" }, { label = "Add ten clicks", chosen = true } }, "the submenu below its way back")
    test.key("Left")
    test.match({ more < whole, test.popup(1).height }, { true, whole }, "the submenu in place, and back")
    test.key("Return")
    test.key("Return")
    test.match(state().clicks, 10, "the submenu's entry")

    -- a graph's bars fill its width in the given order, each as high as its share of the highest; the checks left the rows sorted by price,
    -- so the stock is 25, 40 and 12, and the line marks 20 across it
    tabs = state().rects.tab
    test.click(box.x + tabs.x + tabs.width * 0.02, box.y + tabs.y + tabs.height / 2)
    test.key("Right")
    test.key("Right")
    test.match(state().tab, "Table", "the tab of the table and the graph")
    local graph = state().rects.graph
    local bar = graph.width / 3
    local function pixel(index, fromBottom)
      return test.pixel(box.x + graph.x + bar * (index - 0.5), box.y + graph.y + graph.height * (1 - fromBottom))
    end
    test.match({ pixel(1, 0.1), pixel(2, 0.1), pixel(3, 0.1) }, { "#61AFEF", "#61AFEF", "#61AFEF" }, "every bar starts at the bottom")
    test.match(pixel(2, 0.95), "#61AFEF", "the highest bar fills the graph")
    test.match(pixel(1, 0.95) ~= "#61AFEF" and pixel(3, 0.4) ~= "#61AFEF", true, "lower bars end at their share of the highest")

    -- ui's inspector outlines every element, and names the one under the pointer: the innermost element there, with its id
    local panel = test.rect(1)
    local state = test.session().workspaces[1].windows[1].panels[1].state
    local rect = state.rects.button
    test.call("ui.inspect")
    test.move(panel.x + rect.x + rect.width / 2, panel.y + rect.y + rect.height / 2)
    test.wait(0.2)
    state = test.session().workspaces[1].windows[1].panels[1].state
    test.match(state.inspected, { type = "button", id = "button" }, "the inspected element")
    test.call("ui.inspect")

    -- a list that only scrolled moves its pixels, and ui draws only what they do not show: the items that came into view, its border's
    -- top and bottom, and its scroll bar. Another tab and back draws the list whole, which shows the same pixels
    local tab = state.rects.tab
    test.click(panel.x + tab.x + tab.width * 0.02, panel.y + tab.y + tab.height / 2)
    test.key("Left")
    test.key("Left")
    local list = test.session().workspaces[1].windows[1].panels[1].state.rects.list
    local folder = debug.getinfo(1, "S").source:match("^@(.*[/\\])")
    local function picture(name)
      local path = folder .. name
      test.screenshot(path)
      local file = assert(io.open(path, "rb"))
      local bytes = file:read("a")
      file:close()
      os.remove(path)
      return bytes
    end

    test.wheel(panel.x + list.x + list.width / 2, panel.y + list.y + list.height / 2, -1)
    local moved = picture("scrolled.png")
    test.key("Right")
    test.key("Left")
    test.match(picture("whole.png") == moved, true, "a scrolled list's moved pixels")
  end,
}
