-- help.md becomes a column of ui's elements: texts for the headings and paragraphs, a table, columns for the lists, the quote and the code,
-- and a separator for the line; its tree holds its headings, and Return on a link gives its address
return {
  preset = "preset.lua",
  run = function(test)
    local state = test.session().workspaces[1].windows[1].panels[1].state

    test.match(state, {
      headings = { "1 Sketch help", "2 Keys", "2 Getting started" },
      elements = { "text", "text", "text", "column", "text", "column", "column", "column", "column", "separator", "text" },
    }, "the help")
    assert(test.panel(1).fault == nil, test.panel(1).fault)

    -- a click on the link that starts the first paragraph, below the title, gives its address
    local panel = test.rect(1)
    test.click(panel.x + 24, panel.y + 64)
    test.match(test.panel(1).state.link, "https://github.com/omerfuyar/OpenECS-examples", "the clicked link")

    -- Tab gives the keys to the next text with a link, and Return gives its first link
    test.key("Tab")
    test.key("Return")
    test.match(test.panel(1), { title = "Help: https://github.com/omerfuyar/OpenECS", state = { link = "https://github.com/omerfuyar/OpenECS" } }, "the link of Return")

    -- each link of a text is a stop of Tab: the next Tab stays in the text, on its second link
    test.key("Tab")
    test.key("Return")
    test.match(test.panel(1).state.link, "https://github.com/omerfuyar/OpenECS-std", "the second link")
  end,
}
