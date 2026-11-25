-- a new console's Show dropdown starts from the setting console.show, Warnings and up by default; a console restored from a session
-- keeps its own level
return {
  preset = "preset_show.lua",
  run = function(test)
    test.match(test.setting("console.show"), "Warnings and up", "console.show is Warnings and up by default")
    local levels = {}
    for _, panel in ipairs(test.panels()) do
      if panel.type == "console.log" then
        levels[#levels + 1] = test.panel(panel.id).state.show
      end
    end
    test.match(levels, { "warn", "error" }, "a new console shows Warnings and up, and a restored one its own level")
  end,
}
