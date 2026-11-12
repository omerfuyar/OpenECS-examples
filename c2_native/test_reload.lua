-- a native plugin that reloads loads from a hidden copy of its library, so its build can replace the library; each load makes a new copy, and
-- unloading removes the old one

local folder = debug.getinfo(1, "S").source:match("^@(.*[/\\])") .. "hello_c/"
local windows = package.config:sub(1, 1) == "\\"

-- the name of a library, or of its copy, as the core gives it on this system
local function library(prefix)
  if windows then
    return folder .. prefix .. "hello_c.dll"
  end

  local apple = io.open(folder .. "libhello_c.dylib", "rb")

  if apple then
    apple:close()
    return folder .. prefix .. "libhello_c.dylib"
  end

  return folder .. prefix .. "libhello_c.so"
end

local function exists(path)
  local file = io.open(path, "rb")

  if file then
    file:close()
  end

  return file ~= nil
end

return {
  preset = "preset_reload.lua",
  run = function(test)
    test.match(test.panel(1), { type = "hello_c.greeting", fault = nil })
    assert(exists(library(".reload-0-")), "hello_c loads from a copy of its library")

    -- writing the library again, as a build does, reloads the plugin from a new copy
    local file = assert(io.open(library(""), "rb"))
    local bytes = file:read("a")
    file:close()
    file = assert(io.open(library(""), "wb"))
    file:write(bytes)
    file:close()

    for _ = 1, 40 do
      if exists(library(".reload-1-")) then
        break
      end

      test.wait(0.25)
    end

    assert(exists(library(".reload-1-")), "the reload loads from a new copy")
    assert(not exists(library(".reload-0-")), "the reload removes the old copy")
    test.match(test.panel(1), { type = "hello_c.greeting", title = "Greeting in C", fault = nil }, "the panel after the reload")
  end,
}
