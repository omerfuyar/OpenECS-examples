-- the settings window lists every setting of the tool's plugins, and changes them in the user's settings file

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
    test.match(test.panel(1), { title = "Square, #A3BE8C" }, "the square shows the default colour")

    -- the core's settings file binds the settings window to Alt+W, then ","
    test.key("Alt+W")
    test.key(",")
    assert(window(test), "the settings window is open")

    -- settings are listed by name; the window's keys choose one
    for _ = 1, 100 do
      local selected = window(test).state.selected

      if selected == "shapes.color" then
        break
      end

      test.key(selected < "shapes.color" and "Down" or "Up")
    end

    -- Return edits the value, which is typed as an input method gives text, and Return again sets it
    test.key("Return")

    for _ = 1, #"#A3BE8C" do
      test.key("Backspace")
    end

    test.text("#BF616A")
    test.key("Return")
    test.match(test.panel(1), { title = "Square, #BF616A" }, "the square after the setting changed")
  end,
}
