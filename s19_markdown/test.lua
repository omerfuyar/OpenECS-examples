-- help.md becomes a column of ui's elements: texts for the headings and paragraphs, a table, columns for the lists, the quote and the code,
-- and a separator for the line; its tree holds its headings
return {
  preset = "preset.lua",
  run = function(test)
    local state = test.session().workspaces[1].windows[1].panels[1].state

    test.match(state, {
      headings = { "1 Sketch help", "2 Keys", "2 Getting started" },
      elements = { "text", "text", "text", "column", "text", "column", "column", "column", "column", "separator", "text" },
    }, "the help")
    assert(test.panel(1).fault == nil, test.panel(1).fault)
  end,
}
