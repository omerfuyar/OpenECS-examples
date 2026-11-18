-- the typed pattern filters the log's lines, ignoring case; a pattern that cannot be read says why; Exact text matches the typed text as it is
return {
  preset = "preset.lua",
  run = function(test)
    local function state()
      return test.session().workspaces[1].windows[1].panels[1].state
    end

    test.match(state(), {
      day = "09.11.2026",
      words = { "server", "started", "on", "port", "8080" },
      durations = { "30", "2.4" },
      hidden = "####-##-## ##:##:## WARN  disk ##% full",
      numbers = 16,
      shown = {
        "10:00:05  WARN  disk 91% full",
        "10:01:12  ERROR request /api/items failed: timeout after 30s",
        "10:03:02  ERROR database locked",
        "10:04:15  WARN  slow query took 2.4s",
      },
    }, "error|warn at start")

    -- Tab gives the field the keys; Ctrl+A selects its text, which typing replaces
    test.key("Tab")
    test.key("Ctrl+A")
    test.text("TIMEOUT|locked")
    test.match(state().shown, { "10:01:12  ERROR request /api/items failed: timeout after 30s", "10:03:02  ERROR database locked" }, "timeout or locked")

    test.key("Ctrl+A")
    test.text("(")
    test.match(state(), { shown = {}, problem = "the pattern cannot be read at byte 2: missing closing parenthesis" }, "a pattern that cannot be read")

    -- . matches any character, so a.i matches api and ali; as exact text, it matches nothing
    test.key("Ctrl+A")
    test.text("a.i")
    test.match(#state().shown, 2, "a.i as a pattern")
    test.key("Tab")
    test.key("Space")
    test.match(state(), { exact = true, shown = {} }, "a.i as exact text")
  end,
}
