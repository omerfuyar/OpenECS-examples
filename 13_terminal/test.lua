-- typed commands run on Return, and print what they give
return {
  preset = "preset.lua",
  run = function(test)
    test.text("echo hello")
    test.key("Return")
    test.match(test.session().workspaces[1].windows[1].panels[1].state, { output = "hello" }, "echo")

    test.text("nope")
    test.key("Return")
    test.match(test.session().workspaces[1].windows[1].panels[1].state, { output = "unknown command: nope" }, "an unknown command")
  end,
}
