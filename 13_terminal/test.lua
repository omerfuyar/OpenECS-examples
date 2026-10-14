-- typed commands run on Return, and print what they give
return {
  preset = "preset.lua",
  run = function(test)
    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    test.text("echo hello")
    test.key("Return")
    test.match(state().output, "hello", "echo")

    test.text("nope")
    test.key("Return")
    test.match(state().output, "unknown command: nope", "an unknown command")

    -- a wide character takes two cells, and its right half holds nothing
    test.text("echo 漢字ab")
    test.key("Return")
    test.match(state().cells, { "漢", "", "字", "", "a", "b" }, "the cells of wide characters")
    test.match(state().styles, { "", "", "", "", "", "" }, "the plain style")

    -- bold prints in bold
    test.text("bold hi")
    test.key("Return")
    test.match(state().cells, { "h", "i", " ", " ", " ", " " }, "the cells of bold text")
    test.match(state().styles, { "bold", "bold", "", "", "", "" }, "the bold style")
  end,
}
