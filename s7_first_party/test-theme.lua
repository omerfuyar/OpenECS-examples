-- the settings window changes the theme: "system" follows the system, and a theme's name chooses it; the colours follow it

local LIGHT_BACKGROUND = "#A3A3A3"
-- errors and warnings have colours of their own, readable on each theme's panels
local DARK_ERROR, DARK_WARNING = "#F07178", "#E5C07B"
local LIGHT_ERROR, LIGHT_WARNING = "#A1231B", "#7A5200"

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
    test.match({ test.setting("ecs.colorError"), test.setting("ecs.colorWarning") }, { DARK_ERROR, DARK_WARNING }, "the dark theme's error and warning")

    test.key("Alt+W")
    test.key(",")

    for _ = 1, 100 do
      local selected = window(test).state.selected

      if selected == "ecs.theme" then
        break
      end

      test.key(selected < "ecs.theme" and "Down" or "Up")
    end

    -- Right steps a choice forward: system first, then the themes by name
    local function stepTo(name)
      for _ = 1, 20 do
        test.key("Right")
        if test.setting("ecs.theme") == name then
          return
        end
      end
      error("no theme " .. name)
    end
    test.key("Right")
    test.match(test.setting("ecs.theme"), "dark", "the first theme after system")
    stepTo("light")
    test.match(test.setting("ecs.colorBackground"), LIGHT_BACKGROUND, "the light theme's background")
    test.match({ test.setting("ecs.colorError"), test.setting("ecs.colorWarning") }, { LIGHT_ERROR, LIGHT_WARNING }, "the light theme's error and warning")
    -- the core ships other themes too, each a choice of its own, such as high contrast for dark
    stepTo("highContrastDark")
    test.match({ test.setting("ecs.colorBackground"), test.setting("ecs.colorText"), test.setting("ecs.colorAccent") }, { "#000000", "#FFFFFF", "#FFE14D" },
      "the dark theme of high contrast")
  end,
}
