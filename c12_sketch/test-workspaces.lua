-- the title bar's workspaces' menu, at its right, shows the current workspace's name; a click opens the list of workspaces, and Return switches.
-- The window buttons stay at the bar's right end whatever the menu's name, and a panel moves to another workspace, or to a new one, by menu and by key

local title = dofile(debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "title.lua")
local parts, centre = title.parts, title.centre

-- the workspaces' names, by number
local function names(test)
  local found = {}

  for _, workspace in ipairs(test.session().workspaces) do
    found[#found + 1] = workspace.name
  end

  return found
end

-- the types of a workspace's panels
local function typesIn(test, number)
  local found = {}

  for _, panel in ipairs(test.panels()) do
    if panel.workspace == number then
      found[#found + 1] = panel.type
    end
  end

  table.sort(found)
  return found
end

return {
  preset = "preset.lua",
  run = function(test)
    test.match(parts(test).workspace.label, "C \u{25BE}", "the first workspace's name")
    title.checkMargin(test, 1, "with C")
    title.checkButtons(test, "with C")

    -- the list opens with the first workspace chosen; Down chooses the next one
    test.click(centre(parts(test).workspace.rect))
    test.key("Down")
    test.key("Return")
    test.match({ test.session().currentWorkspace, parts(test).workspace.label }, { 2, "Lua \u{25BE}" }, "the second workspace, by the menu")

    -- a longer name makes the menu wider, and the window buttons stay
    test.click(centre(parts(test).workspace.rect))
    test.key("Down")
    test.key("Down")
    test.key("Return")
    test.match(parts(test).workspace.label, "Side by side \u{25BE}", "the third workspace, by the menu")
    title.checkButtons(test, "with Side by side")

    -- Alt+W, then Shift+1, moves the focused C canvas to the first workspace, which stays hidden
    test.click(test.rect(5).x + 100, test.rect(5).y + 100)
    test.key("Alt+W")
    test.key("Shift+1")
    test.match({ test.session().currentWorkspace, typesIn(test, 1) }, { 3, { "sketch_c.canvas", "sketch_c.canvas", "sketch_c.clock" } }, "a canvas moved to C")

    -- Alt+W, then Shift+N, moves the focused Lua canvas to a new workspace, after the last and named after its title
    test.click(test.rect(6).x + 100, test.rect(6).y + 100)
    test.key("Alt+W")
    test.key("Shift+N")
    test.match({ names(test), test.session().currentWorkspace, typesIn(test, 4) },
      { { "C", "Lua", "Side by side", test.panel(6).title }, 3, { "sketch_lua.canvas" } }, "a canvas moved to a new workspace by key")

    -- the C clock's tab menu ends with To workspace, whose last entry is a new workspace: Up comes round to them from the first entry
    local tab = test.rect(7)
    test.click(tab.x + 20, tab.y - 12, 3)
    test.key("Up")
    test.key("Right")
    test.key("Up")
    test.key("Return")
    test.match({ #names(test), typesIn(test, 5), test.session().currentWorkspace }, { 5, { "sketch_c.clock" }, 3 }, "a clock moved to a new workspace by the menu")
  end,
}
