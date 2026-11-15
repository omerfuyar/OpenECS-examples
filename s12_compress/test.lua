-- the plugin packs its file in every format and unpacks the same text, writes a zip archive that lists and reads back its files,
-- and makes a .tar.gz that it reads back, and that the system's tar reads too
return {
  preset = "preset.lua",
  run = function(test)
    test.match(test.session().workspaces[1].windows[1].panels[1].state, {
      same = { gzip = true, zlib = true, deflate = true, zstd = true },
      entries = { { name = "archive/init.lua" }, { name = "archive/manifest.lua" } },
      readBack = true,
    }, "the archive's state")

    local state = test.session().workspaces[1].windows[1].panels[1].state
    test.match(state.tar, { same = true, names = { "archive/", "archive/run.sh", state.tar.long } }, "the tar archive read back")

    -- the system's tar lists the same entries, with the long name whole and the script executable
    if package.config:sub(1, 1) == "/" then
      local list = assert(io.popen(("tar -tvzf '%s'"):format(state.tarPath)))
      local text = list:read("a")
      list:close()
      assert(text:find("%-rwxr%-xr%-x [^\n]* archive/run%.sh\n"), "tar lists the script as executable:\n" .. text)
      assert(text:find(state.tar.long, 1, true), "tar lists the long name whole:\n" .. text)
    end
  end,
}
