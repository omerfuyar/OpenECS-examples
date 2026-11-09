-- the plugin packs its file in every format and unpacks the same text, and writes a zip archive that lists and reads back its files
return {
  preset = "preset.lua",
  run = function(test)
    test.match(test.session().workspaces[1].windows[1].panels[1].state, {
      same = { gzip = true, zlib = true, deflate = true, zstd = true },
      entries = { { name = "archive/init.lua" }, { name = "archive/manifest.lua" } },
      readBack = true,
    }, "the archive's state")
  end,
}
