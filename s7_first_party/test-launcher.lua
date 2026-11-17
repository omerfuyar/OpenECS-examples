-- a test without a preset starts from the launcher, which lists the presets, then the saved sessions; here, the ones in user/

-- the chosen entry, as the launcher's panel saves it
local function chosen(test)
  return test.session().workspaces[1].windows[1].panels[1].state.selected
end

return {
  presets = "user/presets",
  sessions = "user/sessions",
  run = function(test)
    test.match(chosen(test), { type = "preset", name = "squares" }, "the first entry")

    test.key("Down")
    test.match(chosen(test), { type = "session", name = "drawing" }, "after Down")

    -- a click chooses the entry under it and opens it; a test cannot open one, so the launcher stays
    local panel = test.rect(1)
    test.click(panel.x + 100, panel.y + 116)
    test.match(chosen(test), { type = "preset", name = "squares" }, "after a click on the first entry")

    -- Ctrl+F gives the keys to the search above the list, which shows only the entries that hold each word typed;
    -- Down there chooses among them, and Escape clears the search
    test.key("Ctrl+F")
    test.text("draw")
    test.key("Down")
    test.match(chosen(test), { type = "session", name = "drawing" }, "after a search for a session")
    test.key("Escape")
    test.key("Up")
    test.match(chosen(test), { type = "preset", name = "squares" }, "after the search is cleared")
  end,
}
