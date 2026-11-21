-- A panel that shows what the hash standard plugin gives: the hashes of a text with each algorithm, and of a file read in parts.
-- hash.of hashes data that is all in memory. hash.new gives a hasher, which takes the data in parts, so a large file never has to be read whole.

local ecs = require("ecs")
local draw = require("draw")
local hash = require("hash")

local ALGORITHMS = { "crc32", "md5", "sha1", "sha256", "sha512", "xxh64", "xxh3", "xxh128" }

-- hashes a file in parts of 4 KiB; a plugin reads its own files by its folder
local function hashFile(path, algorithm)
  local file = assert(io.open(path, "rb"))
  local hasher = assert(hash.new(algorithm))

  for part in file:lines(4096) do
    hasher:update(part)
  end

  file:close()

  -- digest ends the hash; the hasher takes no more data after it
  return hasher:digest()
end

-- each panel's state is an object of Checksums, whose functions are methods
local Checksums = {}
Checksums.__index = Checksums

function Checksums.create()
  local state = setmetatable({ text = {} }, Checksums)

  -- each hash is hexadecimal text, as tools such as sha256sum write it
  for _, algorithm in ipairs(ALGORITHMS) do
    state.text[algorithm] = hash.of(algorithm, "abc")
  end

  -- the same file, whole and in parts, gives the same hash
  local path = ecs.plugin.folder .. "init.lua"
  local file = assert(io.open(path, "rb"))
  state.whole = hash.of("sha256", file:read("a"))
  file:close()
  state.parts = hashFile(path, "sha256")
  return state
end

function Checksums:draw(surface)
  surface:fill(0, 0, surface.width, surface.height, "background")
  local font, y = draw.font("ui"), 16

  local function show(text, color)
    draw.text(surface, font, text, 16, y, 16, color)
    y += 24
  end

  show('The hashes of "abc":', "text")

  for _, algorithm in ipairs(ALGORITHMS) do
    show(("%-7s %s"):format(algorithm, self.text[algorithm]), "textDim")
  end

  show("init.lua's SHA-256, whole:    " .. self.whole, "text")
  show("init.lua's SHA-256, in parts: " .. self.parts, self.whole == self.parts and "text" or "accent")
end

-- what the test reads
function Checksums:saveState()
  return { text = self.text, same = self.whole == self.parts }
end

ecs.panel.registerType({
  name = "panel",
  title = "Hashes",

  create = Checksums.create,

  draw = Checksums.draw,

  saveState = Checksums.saveState,
})
