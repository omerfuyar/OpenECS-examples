-- checks of the title bar that the tests of workspaces and of the scale share

local title = {}

-- the parts of the title bar, by kind; the window buttons by their labels
function title.parts(test)
  local found = {}

  for _, part in ipairs(test.titleBar()) do
    found[part.kind == "window" and part.label or part.kind] = part
  end

  return found
end

function title.centre(rect)
  return rect.x + rect.width / 2, rect.y + rect.height / 2
end

-- the workspaces' menu ends before the window buttons, which end at the window's right edge, where the pointer finds them
function title.checkButtons(test, message)
  local bar = title.parts(test)
  local menu, close = bar.workspace.rect, bar.close.rect
  test.match({ menu.x + menu.width <= bar.minimize.rect.x, bar.minimize.rect.x + bar.minimize.rect.width, bar.maximize.rect.x + bar.maximize.rect.width },
    { true, bar.maximize.rect.x, close.x }, message)

  -- the close button under the pointer shows the colour hover, so it is drawn where it is
  test.move(title.centre(close))
  test.match(test.pixel(close.x + 2, close.y + 2), test.setting("ecs.colorHover"), message .. ": the close button is drawn at its place")
  test.move(300, 300)
end

-- the layout leaves a margin of ecs.dividerSize layout units at the window's edges, as between groups
function title.checkMargin(test, id, message)
  local rect, margin = test.rect(id), test.setting("ecs.dividerSize") * test.setting("ecs.scale")
  test.match({ rect.x >= margin, rect.y >= test.titleBar()[1].rect.height + margin }, { true, true }, message .. ": the margin")
end

return title
