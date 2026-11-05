-- Space plugs in a virtual gamepad, which the panel opens when gamepad.added comes; A presses and releases its button a
return {
  preset = "preset.lua",
  run = function(test)
    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    test.key("Space")
    test.wait(0.1)
    test.match(state(), { pads = { "Keyboard" } }, "the virtual gamepad")

    test.key("A")
    test.wait(0.1)
    test.match(state(), { presses = { "a down", "a up" } }, "the presses of its button")
  end,
}
