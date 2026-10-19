-- a canvas popped out into a window of its own goes back into the main window when its grip is dragged there, and the empty window closes
return {
  preset = "preset.lua",
  run = function(test)
    local canvas = test.session().workspaces[1].windows[1][1].panels[1].id
    test.click(test.rect(canvas).x + 300, test.rect(canvas).y + 300)
    test.call("ecs.layout.popOut")
    test.match(test.rect(canvas).window, 2, "the canvas in its own window")

    -- the grip shows at the middle of the panel's top edge while the pointer is near it
    local mainX, mainY = test.window(1)
    local popX, popY = test.window(2)
    local rect = test.rect(canvas)
    local gripX, gripY = rect.x + rect.width / 2, rect.y + 4
    test.move(gripX, gripY)

    -- the core knows where the windows are on the screen, except on Wayland, where both are at 0, 0:
    -- there, a panel dropped outside its window lands in the window that the pointer enters next
    local wayland = mainX == popX and mainY == popY
    -- elsewhere the pop-out window opens at the pointer, over the main window, whose left part it leaves free
    local toX, toY = mainX - popX + 40, mainY - popY + 300

    if wayland then
      toX, toY = -300, 300
    end

    test.drag(gripX, gripY, toX, toY)

    if wayland then
      test.window(1)
      test.move(300, 300)
    end

    test.window(1)
    test.match(test.rect(canvas).window, 1, "the canvas back in the main window")
    test.match(#test.session().workspaces[1].windows, 1, "the pop-out window closed")
  end,
}
