-- the viewer shows each file in its language, and highlight gives the kinds of a line of C in order; Right on the selector shows the next file
return {
  preset = "preset.lua",
  run = function(test)
    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    test.match(state(), {
      name = "sample.c",
      language = "c",
      lines = 18,
      languages = { "c", "lua", "json" },
      -- int main(void) { return 0; } // done: the grammar's query leaves brackets out
      kinds = { "type", "function", "type", "keyword", "number", "punctuation", "comment" },
    }, "the C sample")

    -- Tab gives the selector the keys, and Right chooses the next file
    test.key("Tab")
    test.key("Right")
    test.match(state(), { name = "init.lua", language = "lua" }, "the viewer's own code")
    test.key("Right")
    test.match(state(), { name = "sample.json", language = "json", lines = 8 }, "the JSON sample")
  end,
}
