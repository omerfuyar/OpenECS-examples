-- a change to the plugin's file reloads it, and the panels and the plugin keep their state; a file that fails leaves the plugin disabled, and the
-- next change brings it back

local folder = debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "marks/"

local function read(path)
  local file = assert(io.open(path, "rb"))
  local text = file:read("a")
  file:close()
  return text
end

local function write(path, text)
  local file = assert(io.open(path, "wb"))
  file:write(text)
  file:close()
end

return {
  preset = "preset.lua",
  run = function(test)
    local left = test.rect(1)

    local function placed()
      return test.session().pluginState.marks.state.placed
    end

    -- the core checks the files every second, and reloads a plugin once they stay the same for one check
    local function waitUntil(done, what)
      for _ = 1, 40 do
        if done() then
          return
        end

        test.wait(0.25)
      end

      error("the test waited in vain for " .. what)
    end

    test.click(left.x + 10, left.y + 20)

    local original = read(folder .. "init.lua")
    write(folder .. "init.lua", (original:gsub("return { placed = placed }", "return { placed = placed, reloaded = true }")))
    waitUntil(function() return test.session().pluginState.marks.state.reloaded end, "the reload")
    test.match(test.session().pluginState.marks.state.placed, 1, "the plugin's state after the reload")
    test.match(test.session().workspaces[1].windows[1][1].panels[1].state.dots, { 10, 20 }, "the panel's dots after the reload", true)

    -- a file that fails to run leaves the plugin disabled, and its panels placeholders that keep their state
    write(folder .. "init.lua", original .. "\nthis is not Lua\n")
    waitUntil(function() return test.panel(1).fault ~= nil end, "the failed reload")

    write(folder .. "init.lua", original)
    waitUntil(function() return test.panel(1).fault == nil end, "the plugin to come back")
    test.match(test.session().workspaces[1].windows[1][1].panels[1].state.dots[1], 10, "the panel's first dot after the failed reload")
  end,
}
