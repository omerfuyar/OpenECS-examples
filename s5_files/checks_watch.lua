-- the checks of fs's recursive watch, which the Lua plugin watcher and the C plugin watcher_c pass alike: each watches a folder and the folders
-- inside it, and gives the changes it was told, by their paths in the folder, such as "a/b/deep.txt:added"; plugin is the plugin's name

return function(test, plugin)
  -- a relative path of fs starts at the executable's folder, and Lua's io at the working folder, so the folder's path is whole
  local root = test.call("fs.folder", "executable") .. "examples/s5_files/watched_" .. plugin .. "/"

  local function write(path, text)
    local file = assert(io.open(root .. path, "wb"))
    file:write(text or "Some text.\n")
    file:close()
  end

  -- removes a folder with all in it
  local function removeAll(path)
    for _, entry in ipairs(test.call("fs.list", path, "") or {}) do
      if entry.type == "folder" then
        removeAll(path .. entry.name .. "/")
      else
        os.remove(path .. entry.name)
      end
    end
    test.call("fs.remove", path)
  end

  -- what the plugin was told since the watch began
  local told = {}
  local function look()
    for _, line in ipairs(test.call(plugin .. ".seen", #told + 1)) do
      told[#told + 1] = line
      told[line] = true
    end
  end

  -- waits up to 5 seconds for each change, as fs reads changes ten times a second
  local function waitFor(lines, message)
    for _ = 1, 100 do
      look()
      local all = true
      for _, line in ipairs(lines) do
        all = all and told[line] == true
      end
      if all then
        return
      end
      test.wait(0.05)
    end
    error(("%s: %s waits for %s, and was told %s"):format(plugin, message, table.concat(lines, ", "), table.concat(told, ", ")), 2)
  end

  -- a run that stopped early may have left the folder
  removeAll(root)
  removeAll(root:sub(1, -2) .. "_outside/")
  test.call("fs.makeFolder", root .. "a/b")
  test.call("fs.makeFolder", root .. ".hidden")
  test.match({ test.call(plugin .. ".start", root) }, { true }, plugin .. " watches the folder")

  -- a change in a folder inside a folder that was there when the watch began
  write("a/b/deep.txt")
  waitFor({ "a/b/deep.txt:added" }, "a file written two folders down")

  -- a folder that is moved in with files and folders inside it already: each entry inside it is told as added, and it is watched
  local outside = root:sub(1, -2) .. "_outside/"
  test.call("fs.makeFolder", outside .. "inner")
  local file = assert(io.open(outside .. "one.txt", "wb"))
  file:close()
  file = assert(io.open(outside .. "inner/two.txt", "wb"))
  file:close()
  assert(os.rename(outside:sub(1, -2), root .. "made"))
  waitFor({ "made:added", "made/one.txt:added", "made/inner:added", "made/inner/two.txt:added" }, "a folder moved in")
  write("made/inner/three.txt")
  waitFor({ "made/inner/three.txt:added" }, "a file written in the folder moved in")

  -- a folder that is removed with all in it, and made again at once, as git does when it switches branches: the watched folder is not gone,
  -- and the new folder is watched; inotify and Windows tell it as removed and added in its own folder, and reading folders again may not see it
  removeAll(root .. "a/")
  test.call("fs.makeFolder", root .. "a/b")
  test.wait(0.3)
  write("a/b/again.txt")
  waitFor({ "a/b/again.txt:added" }, "a file written in the folder made again")
  test.match(told[":gone"], nil, plugin .. ": the watched folder is not gone")

  -- a folder whose name starts with a dot is an entry, but what is in it is not watched: a change in it is not told, though one after it, in
  -- another folder, is
  write(".hidden/inside.txt")
  test.call("fs.makeFolder", root .. ".made")
  waitFor({ ".made:added" }, "a folder whose name starts with a dot")
  write(".made/inside.txt")
  write("a/after.txt")
  waitFor({ "a/after.txt:added" }, "a file written after the ones in the dot folders")
  test.match(told[".hidden/inside.txt:added"], nil, plugin .. ": a dot folder is not entered")
  test.match(told[".made/inside.txt:added"], nil, plugin .. ": a dot folder made later is not entered")

  -- the watched folder itself, removed, is gone
  removeAll(root)
  waitFor({ ":gone" }, "the watched folder removed")
end
