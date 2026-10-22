-- Delete clears a canvas; with unsaved strokes, the canvas asks first, in a message dialog that the core draws over the window
return {
  preset = "preset.lua",
  run = function(test)
    -- the canvas is the first group of a workspace's split
    local function canvas(workspace)
      return test.session().workspaces[workspace].windows[1][1].panels[1]
    end

    local function stroke(workspace)
      local rect = test.rect(canvas(workspace).id)
      test.drag(rect.x + 50, rect.y + 60, rect.x + 200, rect.y + 150)
    end

    -- the C canvas asks with ECSDialog_ShowMessage; Escape presses the last button, Keep
    stroke(1)
    test.key("Delete")
    local dialog = test.dialog()
    test.match({ dialog.title, dialog.buttons }, { "Clear canvas", { "Clear", "Keep" } }, "the C canvas's question")
    test.key("Escape")
    test.match(#canvas(1).state.strokes, 1, "the kept stroke")

    -- Return presses the chosen button, at first the first: Clear
    test.key("Delete")
    test.key("Return")
    test.match(test.dialog(), nil, "the dialog after Return")
    test.match(#canvas(1).state.strokes, 0, "the cleared C canvas")

    -- the Lua canvas asks with ecs.dialog.showMessage, which gives the pressed button's number; Right and Return press Keep
    test.call("ecs.workspace.switch2")
    stroke(2)
    test.key("Delete")
    test.match(test.dialog().title, "Clear canvas", "the Lua canvas's question")
    test.key("Right")
    test.key("Return")
    test.match(#canvas(2).state.strokes, 1, "the stroke Keep kept")
  end,
}
