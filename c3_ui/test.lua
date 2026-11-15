-- the controls in Lua, on workspace 1: each control changes the panel's state, as the checks that the C plugin passes too say

local checks = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "checks.lua")

return {
  preset = "preset.lua",
  run = function(test)
    checks(test, 1, "Controls")

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

    -- a right click beside the elements reaches the root's onMenu, which opens the panel's menu there: its entries are a row each, with a line between the
    -- first and the second, and Reset is enabled only when there are clicks
    local clicks = state().clicks
    local corner = test.rect(1)
    test.click(corner.x + corner.width - 20, corner.y + corner.height - 20, 3)
    local menu = test.popup(1)
    test.click(menu.x + 10, menu.y + 10)
    test.match(state().clicks, clicks + 1, "the menu's first entry")
    test.click(corner.x + corner.width - 20, corner.y + corner.height - 20, 3)
    test.key("Down")
    test.key("Return")
    test.match(state().clicks, 0, "Down goes past the line to the last entry")

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
  end,
}
