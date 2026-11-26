-- helpers for the core's menus that the tests of tabs and of workspaces share

local menu = {}

-- chooses the entry with a label in the open menu: Down moves the choice until it is there, so an entry added before it changes nothing
function menu.choose(test, label)
  for _ = 1, #test.menu() do
    for _, entry in ipairs(test.menu()) do
      if entry.chosen and entry.label == label then
        return
      end
    end

    test.key("Down")
  end

  error(("the menu has no entry '%s'"):format(label), 2)
end

-- whether a pixel shows one of the colours of settings; a menu kept inside the window may end at its edge, and a pixel outside it
-- shows none
local function shows(test, x, y, settings)
  local inside, pixel = pcall(test.pixel, x, y)

  for _, setting in ipairs(settings) do
    if inside and pixel == test.setting(setting) then
      return true
    end
  end

  return false
end

-- from a point of the open menu's background, the first point in a direction that is not its background
local function edge(test, x, y, dx, dy)
  -- strides of 8, then single steps
  for stride = 8, 1, -7 do
    while shows(test, x + stride * dx, y + stride * dy, { "ecs.colorOverlay" }) do
      x, y = x + stride * dx, y + stride * dy
    end
  end

  return x + dx, y + dy
end

-- the open menu whose left edge is at x, with y in its height, draws no text in the padding at its right: each entry's keys end an
-- entry's padding before the menu's own, as its label starts at its left, so the widest keys do not touch the edge. The menu's
-- background gets a colour that nothing else has, and no transparency, so its edges are found by colour
function menu.checkRightEdge(test, x, y, message)
  test.setSetting("ecs.colorOverlay", "#FF00FF")
  local _, top = edge(test, x + 3, y, 0, -1)
  local _, bottom = edge(test, x + 3, y, 0, 1)
  local right = edge(test, x + 3, top + 5, 1, 0)
  local drawn = {}

  for _, column in ipairs({ right - 8, right - 11 }) do
    for row = top + 6, bottom - 6 do
      if not shows(test, column, row, { "ecs.colorOverlay", "ecs.colorSelected", "ecs.colorFrame" }) then
        drawn[#drawn + 1] = ("text at %d, %d"):format(column, row)
        break
      end
    end
  end

  test.setSetting("ecs.colorOverlay", nil)
  test.match(drawn, {}, message)
end

return menu
