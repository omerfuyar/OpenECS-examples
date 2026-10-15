-- typed text goes into the focused field, and Backspace removes a whole character
return {
  preset = "preset.lua",
  run = function(test)
    test.text("Hello, wörld")
    test.key("Backspace")
    test.key("Backspace")
    test.key("Backspace")
    test.text("rld!")

    test.match(test.session().workspaces[1].windows[1].panels[1].state, { text = "Hello, wörld!" })

    -- a held key that an input method, such as fcitx5, repeats: each repeat is a release and a press with the first press's own time;
    -- SDL keeps that stale time, and on the release it sends at once every repeat it thinks it missed, which the core drops
    test.keyEvent("A", true, 100)
    test.text("a")

    for _ = 1, 5 do
      test.keyEvent("A", false, 100)
      test.keyEvent("A", true, 100)
      test.text("a")
    end

    for _ = 1, 9 do
      test.keyEvent("A", true, 400, true)
      test.text("a")
    end

    test.keyEvent("A", false, 430)
    test.match(test.session().workspaces[1].windows[1].panels[1].state, { text = "Hello, wörld!aaaaaa" }, "one letter for each of the input method's presses")

    -- without an input method, SDL's own repeats of a held key type as usual
    test.keyEvent("B", true, 1000)
    test.text("b")
    test.keyEvent("B", true, 1500, true)
    test.text("b")
    test.keyEvent("B", false, 1530)
    test.match(test.session().workspaces[1].windows[1].panels[1].state, { text = "Hello, wörld!aaaaaabb" }, "SDL's repeat")
  end,
}
