-- Packs this plugin's files in each of compress's formats and unpacks them again, then writes them into a zip archive and reads it back.
-- Lua's io library reads the files; compress works on their texts, and on archives by their paths.

local ecs = require("ecs")
local compress = require("compress")
local ui = require("ui")

local FORMATS = { "gzip", "zlib", "deflate", "zstd" }
local FILES = { "init.lua", "manifest.lua" }

local function readFile(path)
  local file = assert(io.open(path, "rb"))
  local text = file:read("a")
  file:close()
  return text
end

local function pack(state)
  local text = readFile(ecs.plugin.folder .. "init.lua")
  state.lines = { ("init.lua: %d bytes"):format(#text) }
  state.same = {}

  for _, format in ipairs(FORMATS) do
    -- the level is 1 to 9 for zlib's formats and up to 22 for zstd; 0 is the format's default; a call that fails gives nothing and why, which assert raises
    local packed = assert(compress.pack(format, text, 0))

    -- unpack tells gzip, zlib and zstd by their first bytes when the format is empty; deflate has no header, so it is named
    local unpacked = compress.unpack(format == "deflate" and "deflate" or "", packed)
    state.same[format] = unpacked == text
    table.insert(state.lines, ("%s: %d bytes"):format(format, #packed))
  end
end

local function archive(state)
  -- the archive goes beside the plugin's files; a name that ends with .ignore stays out of git
  local path = ecs.plugin.folder .. "archive.ignore"
  local files = {}

  for _, name in ipairs(FILES) do
    files[#files + 1] = { name = "archive/" .. name, data = readFile(ecs.plugin.folder .. name) }
  end

  -- a function that fails gives false or nothing, and why
  local written, problem = compress.zipWrite(path, files, 9)
  state.entries = written and compress.zipList(path) or {}
  state.problem = problem

  -- a file comes back unpacked, checked against the checksum the archive keeps
  state.readBack = compress.zipRead(path, "archive/manifest.lua") == readFile(ecs.plugin.folder .. "manifest.lua")

  for _, entry in ipairs(state.entries) do
    table.insert(state.lines, ("%s in the archive: %d bytes, packed to %d"):format(entry.name, entry.size, entry.packedSize))
  end
end

ecs.panel.registerType({
  name = "panel",
  title = "Archive",

  create = function(panel)
    local state = { panel = panel }
    pack(state)
    archive(state)
    return state
  end,

  draw = function(state, surface)
    local rows = {}

    for _, line in ipairs(state.lines) do
      rows[#rows + 1] = ui.text(line)
    end

    rows[#rows + 1] = ui.text(state.problem or "Every format unpacks to the same text.")
    ui.show(state.panel, surface, ui.column({ padding = 12, gap = 8 }, rows))
  end,

  event = function(state, event)
    ui.event(state.panel, event)
  end,

  destroy = function(state)
    ui.forget(state.panel)
  end,

  saveState = function(state)
    return { same = state.same, entries = state.entries, readBack = state.readBack, problem = state.problem }
  end,
})
