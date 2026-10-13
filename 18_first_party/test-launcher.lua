-- a test without a preset starts from the launcher, which lists the presets, then the saved sessions; here, the ones in user/

-- the chosen entry, as the launcher's panel saves it
local function chosen(test)
  return test.session().workspaces[1].windows[1].panels[1].state.selected
end

return {
  presets = "user/presets",
  sessions = "user/sessions",
  run = function(test)
    test.match(chosen(test), { kind = "preset", name = "squares" }, "the first entry")

    test.key("Down")
    test.match(chosen(test), { kind = "session", name = "drawing" }, "after Down")

    -- a click chooses the entry under it and opens it; a test cannot open one, so the launcher stays
    local list = test.rect(1)
    test.click(list.x + 100, list.y + 90)
    test.match(chosen(test), { kind = "preset", name = "squares" }, "after a click on the first entry")
  end,
}
