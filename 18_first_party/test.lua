-- the panel list shows every panel type of the tool's plugins, and opens the chosen one where the focused panel is

-- a panel of a type in the main window's layout, if one is open
local function find(test, type)
  local function search(node)
    for _, panel in ipairs(node.panels or {}) do
      if panel.type == type then
        return panel
      end
    end

    for _, child in ipairs(node) do
      local found = search(child)

      if found then
        return found
      end
    end
  end

  return search(test.session().workspaces[1].windows[1])
end

return {
  preset = "preset.lua",
  run = function(test)
    -- the core's settings file binds the panel list to Alt+W, then N
    test.key("Alt+W")
    test.key("N")
    local list = assert(find(test, "panels.list"), "the panel list is open")

    -- the types are listed by plugin, then by title, and the list leaves itself out: settings' window, then shapes' frame and square
    test.match(list.state.selected, "settings.window", "the first type")
    test.key("Down")
    test.match(find(test, "panels.list").state.selected, "shapes.frame", "after Down")

    -- Return opens a panel of the chosen type in the group of the panel that had the focus
    test.key("Return")
    test.match(find(test, "shapes.frame"), { type = "shapes.frame" }, "the frame opened")
  end,
}
