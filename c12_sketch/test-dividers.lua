-- a divider's drag sizes its split; where splits meet, a drag sizes both at once

return {
  preset = "preset.lua",
  run = function(test)
    -- the side by side workspace: the canvases side by side above the clocks
    test.call("ecs.workspace.switch3")
    local gap = test.setting("ecs.dividerSize") * test.setting("ecs.scale")
    local window = test.session().workspaces[3].windows[1]
    local cId, luaId, clockId = window[1][1].panels[1].id, window[1][2].panels[1].id, window[2].panels[1].id
    local c, lua, clock = test.rect(cId), test.rect(luaId), test.rect(clockId)

    -- sizes may move by a pixel as the layout rounds them
    local function near(a, b)
      return math.abs(a - b) <= 1
    end

    local function sizes()
      local nowC, nowLua, nowClock = test.rect(cId), test.rect(luaId), test.rect(clockId)
      return { nowC.width, nowLua.width, nowC.height, nowLua.height, nowClock.height }
    end

    local function check(expected, message)
      local actual = sizes()
      local same = {}

      for i = 1, #expected do
        same[i] = near(actual[i], expected[i])
      end

      test.match(same, { true, true, true, true, true }, message .. ": " .. table.concat(actual, ", "))
    end

    -- the divider under the Lua canvas, away from where the splits meet, sizes the rows alone
    local barY = c.y + c.height + gap / 2
    test.drag(lua.x + lua.width / 2, barY, lua.x + lua.width / 2, barY - 20)
    check({ c.width, lua.width, c.height - 20, lua.height - 20, clock.height + 20 }, "the divider between the rows")
    c, lua, clock = test.rect(cId), test.rect(luaId), test.rect(clockId)

    -- where the canvases' divider ends on the rows' divider, the drag moves both
    local x, y = c.x + c.width + gap / 2, c.y + c.height + gap / 2
    test.drag(x, y, x + 40, y + 30)
    check({ c.width + 40, lua.width - 40, c.height + 30, lua.height + 30, clock.height - 30 }, "where the splits meet")
  end,
}
