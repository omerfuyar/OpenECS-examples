-- the key list changes keys in the user's settings, which win over the preset's: a new key for a function, Reset back to the preset's,
-- Remove, which takes a key away with false, and a key added for a function; a search shows only the rows that match it
return {
  preset = "preset.lua",
  run = function(test)
    local counter, list
    for _, panel in ipairs(test.panels()) do
      if panel.type == "counter.panel" then
        counter = panel.id
      elseif panel.type == "keys.list" then
        list = test.rect(panel.id)
      end
    end
    local function count()
      return test.panel(counter).state.count
    end
    local function press(key)
      local before = count()
      test.key(key)
      return count() - before
    end
    -- the search shows one row, so its key and buttons are at the same place each time
    local function search(text)
      test.click(list.x + 400, list.y + 62)
      test.key("Ctrl+A")
      test.key("Backspace")
      test.text(text)
    end
    -- the row's key and buttons are at its right side, so their places are measured from the panel's right edge, whatever its width
    local right = list.x + list.width
    local key, reset, alone = list.x + list.width * 0.75, right - 57, right - 76
    local row = list.y + 198

    test.match(press("Ctrl+J"), 1, "the preset's key counts")

    -- a click on the key, then a key press, binds the new key and takes the old one away
    search("count")
    test.click(key, row)
    test.key("Ctrl+L")
    test.match({ press("Ctrl+L"), press("Ctrl+J") }, { 1, 0 }, "the new key counts, and the old one does nothing")

    -- Reset takes the user's binding away; the old key stays removed, which its own row shows, and its Reset brings it back
    test.click(reset, row)
    test.match(press("Ctrl+L"), 0, "Reset takes the new key away")
    search("ctrl+j")
    test.click(reset, row)
    test.match(press("Ctrl+J"), 1, "Reset brings the preset's key back")

    -- Remove takes the preset's key away with false in the user's settings
    search("count")
    test.click(alone, row)
    test.match(press("Ctrl+J"), 0, "Remove takes the key away")

    -- a function and a key add a binding: the dropdown searches what is typed, and Return chooses
    test.click(list.x + 200, list.y + 126)
    for letter in ("count"):gmatch(".") do
      test.key(letter:upper())
    end
    test.key("Return")
    test.click(right - 96, list.y + 126)
    test.key("Ctrl+K")
    test.match(press("Ctrl+K"), 1, "the added key counts")

    -- the functions are in folders by their names' dots, a folder at a time: Return opens the one hovered, counter, the first, below
    -- the way back, Left goes up to the folders, Right opens it again, and Return chooses count, the first in it
    test.click(list.x + 200, list.y + 126)
    local top = test.popup(1).height
    test.key("Return")
    local inside = test.popup(1).height
    test.key("Left")
    local back = test.popup(1).height
    test.key("Right")
    test.match({ inside < top, back, test.popup(1).height }, { true, top, inside }, "the folders, and back into counter")
    test.key("Return")
    test.click(right - 96, list.y + 126)
    test.key("Ctrl+M")
    test.match(press("Ctrl+M"), 1, "the key added from the folder counts")

    -- while the core waits for the key after the prefix, the key list shows the keys after it in a popup, which closes when the key comes;
    -- the counter's own key after the prefix counts
    local before = count()
    test.key("Escape")
    test.key("Alt+W")
    test.match(pcall(test.popup, 1), true, "the keys after the prefix show")
    test.key("C")
    test.match({ pcall(test.popup, 1), count() - before }, { false, 1 }, "the list closes, and the counter's key after the prefix counts")

    -- the title bar's menu Tools holds the counter's entry, after the core's menus
    local tools = false
    for _, part in ipairs(test.titleBar()) do
      tools = tools or (part.kind == "menu" and part.label == "Tools")
    end
    test.match(tools, true, "the title bar's menu Tools")
  end,
}
