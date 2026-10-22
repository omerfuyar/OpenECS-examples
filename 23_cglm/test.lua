-- the cube in Lua and the cube in C make the same matrices, one with the cglm plugin's functions and one with cglm's own;
-- the plugin's results are what the math gives, and a drag turns each cube by as much; the core's Shift+1 after the prefix moves a cube to workspace 1
return {
  preset = "preset.lua",
  run = function(test)
    local function state(workspace)
      return test.session().workspaces[workspace].windows[1].panels[1].state
    end

    local function near(a, b, message)
      assert(math.abs(a - b) < 1e-4, ("%s: %s, not %s"):format(message, a, b))
    end

    -- the last corner, at the cube's first turn, is above and to the right of the view's centre, in a view from 0 to 1 each way
    local lua = state(1)
    near(lua.turn, 0.6, "the first turn")
    assert(lua.corner.x > 0.5 and lua.corner.x < 1 and lua.corner.y > 0.5 and lua.corner.y < 1, "the corner is in the view's top right")
    assert(lua.drawn > 0, "the cube is drawn")

    -- each check is a difference that must be about 0, or a known result
    for name, difference in pairs(lua.checks) do
      if name ~= "length" and name ~= "singular" then
        assert(difference < 1e-4, ("cglm's %s is off by %s"):format(name, difference))
      end
    end

    near(lua.checks.length, 5, "the length of (3, 4, 0)")
    test.match(lua.checks.singular, 0, "a matrix without an inverse gives an empty buffer")

    -- C's cube, at the same turn, puts the corner at the same place
    local c = state(2)
    near(c.turn, lua.turn, "C's turn")
    near(c.corner.x, lua.corner.x, "C's corner across")
    near(c.corner.y, lua.corner.y, "C's corner up")

    -- a drag of 100 layout units turns each cube by 1
    local panel = test.rect(1)
    local x, y = panel.x + panel.width / 2, panel.y + panel.height / 2
    test.drag(x, y, x + 100, y)
    near(state(1).turn, 1.6, "the turn after a drag")
    assert(state(1).corner.x ~= lua.corner.x, "the drag moves the corner")

    test.call("ecs.workspace.switch2")
    panel = test.rect(2)
    x, y = panel.x + panel.width / 2, panel.y + panel.height / 2
    test.drag(x, y, x + 100, y)
    near(state(2).turn, 1.6, "C's turn after a drag")
    near(state(2).corner.x, state(1).corner.x, "C's corner across after the drags")
    near(state(2).corner.y, state(1).corner.y, "C's corner up after the drags")

    -- the prefix, then Shift+1, moves the focused panel to workspace 1, into the group of the cube in Lua
    test.key("Alt+W")
    test.key("Shift+1")
    test.match(#test.session().workspaces[1].windows[1].panels, 2, "the panels of workspace 1 after Shift+1")
    test.match(#test.session().workspaces[2].windows, 0, "workspace 2 is left without panels")
  end,
}
