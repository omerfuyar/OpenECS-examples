-- Packs this plugin's files in each of compress's formats and unpacks them again, then writes them into a zip archive and reads it back,
-- and makes a tar archive, packed with gzip as a .tar.gz, and reads it back.
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

-- each panel's state is an object of Archive, whose functions are methods
local Archive = {}
Archive.__index = Archive

function Archive:pack()
  local text = readFile(ecs.plugin.folder .. "init.lua")
  self.lines = { ("init.lua: %d bytes"):format(#text) }
  self.same = {}

  for _, format in ipairs(FORMATS) do
    -- each format is a namespace of compress, with its pack and unpack: compress.gzip.pack, and so on
    -- the level is 1 to 9 for zlib's formats and up to 22 for zstd; 0 is the format's default; a call that fails gives nothing and why, which assert raises
    local packed = assert(compress[format].pack(text, 0))

    -- compress.unpack tells gzip, zlib and zstd by their first bytes; deflate has no header, so its own unpack is called
    local unpacked = format == "deflate" and compress.deflate.unpack(packed) or compress.unpack(packed)
    self.same[format] = unpacked == text
    table.insert(self.lines, ("%s: %d bytes"):format(format, #packed))
  end
end

function Archive:archive()
  -- the archive goes beside the plugin's files; a name that ends with .ignore stays out of git
  local path = ecs.plugin.folder .. "archive.ignore"
  local files = {}

  for _, name in ipairs(FILES) do
    files[#files + 1] = { name = "archive/" .. name, data = readFile(ecs.plugin.folder .. name) }
  end

  -- a function that fails gives false or nothing, and why
  local written, problem = compress.zip.write(path, files, 9)
  self.entries = written and compress.zip.list(path) or {}
  self.problem = problem

  -- a file comes back unpacked, checked against the checksum the archive keeps
  self.readBack = compress.zip.read(path, "archive/manifest.lua") == readFile(ecs.plugin.folder .. "manifest.lua")

  for _, entry in ipairs(self.entries) do
    table.insert(self.lines, ("%s in the archive: %d bytes, packed to %d"):format(entry.name, entry.size, entry.packedSize))
  end
end

function Archive:tarball()
  -- a tar archive is made in memory, so gzip packs it into a .tar.gz; a name that ends with / is a folder,
  -- and a long name, up to 255 bytes, is split at a slash, as the ustar format keeps it
  local long = "archive/" .. ("deep/"):rep(24) .. "manifest.lua"
  local files = {
    { name = "archive/" },
    { name = "archive/run.sh", data = "#!/bin/sh\necho run\n", executable = true },
    { name = long, data = readFile(ecs.plugin.folder .. "manifest.lua") },
  }
  local packed = assert(compress.gzip.pack(assert(compress.tar.pack(files)), 0))
  self.tarPath = ecs.plugin.folder .. "archive.tar.gz.ignore"
  local file = assert(io.open(self.tarPath, "wb"))
  file:write(packed)
  file:close()

  -- tar.unpack gives the same tables back
  local back = assert(compress.tar.unpack(assert(compress.gzip.unpack(packed))))
  self.tar = { long = long, names = {}, same = #back == #files }
  for i, entry in ipairs(back) do
    self.tar.names[i] = entry.name
    self.tar.same = self.tar.same and entry.name == files[i].name and entry.data == (files[i].data or "") and entry.executable == (files[i].executable or false)
  end
  table.insert(self.lines, ("a .tar.gz of %d entries: %d bytes"):format(#back, #packed))
end

function Archive:extract()
  -- extract writes every entry of an archive into a folder, under its name
  local folder = ecs.plugin.folder .. "extracted.ignore/"
  local done, problem = compress.zip.extract(ecs.plugin.folder .. "archive.ignore", folder)
  self.extracted = done and readFile(folder .. "archive/manifest.lua") == readFile(ecs.plugin.folder .. "manifest.lua") or problem

  -- an entry whose name goes up with .. or is absolute would write outside the folder, so extract refuses the archive
  self.refused = {}

  for _, name in ipairs({ "../outside.txt", "/outside.txt" }) do
    local path = ecs.plugin.folder .. "unsafe.ignore"
    assert(compress.zip.write(path, { { name = name, data = "outside" } }, 0))
    local _, why = compress.zip.extract(path, folder)
    self.refused[#self.refused + 1] = why
  end

  -- data that no format packed cannot be unpacked
  self.garbage = select(2, compress.unpack("these bytes were never packed"))
end

function Archive.create(panel)
  local state = setmetatable({ panel = panel }, Archive)
  state:pack()
  state:archive()
  state:tarball()
  state:extract()
  return state
end

function Archive:view()
  local rows = {}

  for _, line in ipairs(self.lines) do
    rows[#rows + 1] = ui.text(line)
  end

  rows[#rows + 1] = ui.text(self.problem or "Every format unpacks to the same text.")
  return ui.column({ padding = 12, gap = 8 }, rows)
end

function Archive:saveState()
  return { same = self.same, entries = self.entries, readBack = self.readBack, problem = self.problem, tar = self.tar, tarPath = self.tarPath,
    extracted = self.extracted, refused = self.refused, garbage = self.garbage }
end

ecs.panel.registerType(ui.panelType({
  name = "panel",
  title = "Archive",

  create = Archive.create,

  view = Archive.view,

  saveState = Archive.saveState,
}))
