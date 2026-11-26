-- a handle that Lua's collector frees right after a call into C, while the call still runs, may release a Lua callback: watches with Lua
-- callbacks are freed while draw.font's call through the FFI runs, and the program goes on (OpenECS DESIGN 10.6)
return {
  preset = "preset_watch.lua",
  run = function(test)
    test.call("watcher.collectInCalls", "examples/s5_files/")
    test.match(test.errors(), {}, "the errors")
  end,
}
