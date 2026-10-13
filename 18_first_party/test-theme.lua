-- the settings window changes the theme: "system" follows the system, and "dark" and "light" choose one; the colours follow it

local LIGHT_BACKGROUND = "#D9DCE1"

-- the settings window's panel, if it is open
local function window(test)
  for _, panel in ipairs(test.session().workspaces[1].windows[1].panels or {}) do
    if panel.type == "settings.window" then
      return panel
    end
  end
end

return {
  preset = "preset.lua",
  run = function(test)
    test.match(test.setting("ecs.theme"), "system", "the theme at start")

    test.key("Alt+W")
    test.key(",")

    for _ = 1, 100 do
      local selected = window(test).state.selected

      if selected == "ecs.theme" then
        break
      end

      test.key(selected < "ecs.theme" and "Down" or "Up")
    end

    -- Right steps a choice forward: system, then dark, then light
    test.key("Right")
    test.key("Right")
    test.match(test.setting("ecs.theme"), "light", "the theme after two steps")
    test.match(test.setting("ecs.colorBackground"), LIGHT_BACKGROUND, "the light theme's background")
  end,
}
