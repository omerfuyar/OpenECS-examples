-- a manifest that is not valid is reported in the log, with why, and its plugin is left out of the list: a plugin named prefix, which
-- is the scope of the keys after the prefix, and a plugin whose name has a dot, which the names it registers could not be told from
return {
  preset = "preset-manifests.lua",
  run = function(test)
    -- the core emits the log's lines as ecs.logged in the next pass of the main loop
    test.wait()
    local state = test.panel(1).state
    local listed = {}

    for _, name in ipairs(state.listed) do
      listed[name] = true
    end

    test.match({ listed.lister, listed.prefix or false, listed["with.dot"] or false }, { true, false, false }, "the lister is listed, and the other two are not")
    test.match(#state.refused, 2, "the two manifests that are not valid")
    local reasons = table.concat(state.refused, "\n")
    assert(reasons:find("'name' must not be 'prefix', as a plugin's name is the scope of keys for its panels", 1, true), reasons)
    assert(reasons:find("'name' must have no dot", 1, true), reasons)
  end,
}
