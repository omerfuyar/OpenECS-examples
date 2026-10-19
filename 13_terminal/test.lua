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

    -- Ctrl and + makes the font larger, so fewer columns fit; Ctrl and - makes it smaller, and Ctrl+0 sets it back
    local columns = state().columns
    test.key("Ctrl+=")
    test.match(state().size, 18, "the larger font")
    test.match(state().columns < columns, true, "fewer columns")

    -- a line that no longer fits wraps onto the next row instead of losing its end, and joins again when it fits;
    -- it fills most of a row now, however wide the window is
    local long = string.rep("wrap me ", (state().columns - 12) // 8) .. "end"
    test.text("echo " .. long)
    test.key("Return")

    for _ = 1, 6 do
      test.key("Ctrl+=")
    end

    test.match(state().columns < #long, true, "a row narrower than the line")
    test.match(state().screen:find(long, 1, true) ~= nil, true, "the line, wrapped")

    for _ = 1, 6 do
      test.key("Ctrl+-")
    end

    test.match(state().screen:find(long, 1, true) ~= nil, true, "the line, joined again")
    test.key("Ctrl+-")
    test.key("Ctrl+-")
    test.match(state().size, 14, "the smaller font")
    test.key("Ctrl+0")
    test.match({ state().size, state().columns }, { 16, columns }, "the font size set back")
  end,
}
