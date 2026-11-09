-- the plugin list disables and enables plugins while the tool runs: a disabled plugin's panels wait as placeholders, and come back when it is enabled

local find

-- chooses a plugin in the plugin list with its keys
local function choose(test, name)
  for _ = 1, 100 do
    local selected = find(test, "plugins.list").state.selected

    if selected == name then
      return
    end

    test.key(selected < name and "Down" or "Up")
  end
end

-- a panel of a type in the main window's layout, if one is open
function find(test, type)
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

-- the open panel of a type, as test.panel gives it
local function panelOf(test, type)
  for i = 1, #test.panels() do
    if test.panel(i).type == type then
      return test.panel(i)
    end
  end
end

return {
  preset = "preset-plugins.lua",
  run = function(test)
    -- the core's settings file binds the plugin list to Alt+W, then ;
    test.key("Alt+W")
    test.key(";")
    assert(find(test, "plugins.list"), "the plugin list is open")

    -- the list holds every plugin in the plugin folders, by name; its keys choose one
    choose(test, "shapes")
    test.match(find(test, "plugins.list").state.selected, "shapes", "the chosen plugin")
    test.match(panelOf(test, "shapes.square"), { title = "Square, #A3BE8C", fault = nil }, "the square before")

    -- Return disables shapes, and badges, which needs it: their panels wait as placeholders, and the session lists them as disabled
    test.key("Return")
    test.match(test.session().disabled, { "shapes", "badges" }, "shapes and the plugin that needs it")
    assert(panelOf(test, "shapes.square").fault, "the square is a placeholder")
    assert(panelOf(test, "badges.badge").fault, "the badge is a placeholder")

    -- Return again enables shapes alone, and the square comes back
    test.key("Return")
    test.match(test.session().disabled, { "badges" }, "badges stays disabled")
    test.match(panelOf(test, "shapes.square"), { title = "Square, #A3BE8C", fault = nil }, "the square after")

    -- enabling badges enables the plugins it needs, and the badge comes back
    choose(test, "badges")
    test.key("Return")
    test.match(test.session().disabled, {}, "no plugin is disabled")
    test.match(panelOf(test, "badges.badge"), { title = "Badge", fault = nil }, "the badge after")

    -- each standard plugin registers the same things again when it is enabled again; the plugin list needs ui, draw and image, so they stay
    for _, name in ipairs({ "audio", "cglm", "compress", "fs", "gamepad", "gltf", "gpu", "hash", "launcher", "mixer", "net", "notify", "panels", "parse", "process", "settings", "sqlite", "textgrid", "web" }) do
      choose(test, name)
      test.key("Return")
      test.match(test.session().disabled[1], name, name .. " is disabled")

      -- the plugins that need it were disabled with it, such as audio with mixer; each is enabled again
      for _ = 1, 5 do
        local disabled = test.session().disabled[1]

        if not disabled then
          break
        end

        choose(test, disabled)
        test.key("Return")
      end

      test.match(test.session().disabled, {}, name .. " is enabled again")
    end
  end,
}
