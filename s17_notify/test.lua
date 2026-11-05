-- Return sends a notification; the test runs where no notification service may be, so it checks that send gave an id or a reason
return {
  preset = "preset.lua",
  run = function(test)
    test.key("Return")
    test.match(test.session().workspaces[1].windows[1].panels[1].state, { sent = 1, answered = true }, "after Return")
  end,
}
