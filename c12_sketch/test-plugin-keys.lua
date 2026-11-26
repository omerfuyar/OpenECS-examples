-- each plugin binds Ctrl+H to its highlight with its own name as the scope, so the key works while its canvas or its clock has the focus,
-- and not while a panel of the other plugin has it
return {
  preset = "preset.lua",
  run = function(test)
    for workspace, plugin in ipairs({ "sketch_c", "sketch_lua" }) do
      test.call("ecs.workspace.switch" .. workspace)
      local split = test.session().workspaces[workspace].windows[1]

      local function focus(group)
        local rect = test.rect(split[group].panels[1].id)
        test.click(rect.x + rect.width / 2, rect.y + rect.height / 2)
      end

      focus(1)
      test.key("Ctrl+H")
      test.match(test.setting(plugin .. ".brushColor"), "yellow", plugin .. ": Ctrl+H on the canvas")
      focus(2)
      test.key("Ctrl+H")
      test.match(test.setting(plugin .. ".brushColor") ~= "yellow", true, plugin .. ": Ctrl+H on the clock")
    end

    -- the side by side workspace: the C canvas's Ctrl+H is the C plugin's alone
    test.call("ecs.workspace.switch3")
    local rect = test.rect(test.session().workspaces[3].windows[1][1][1].panels[1].id)
    test.click(rect.x + rect.width / 2, rect.y + rect.height / 2)
    test.key("Ctrl+H")
    test.match({ test.setting("sketch_c.brushColor"), test.setting("sketch_lua.brushColor") }, { "yellow", "green" }, "Ctrl+H on the C canvas")
  end,
}
