-- Watches a folder and the folders inside it with fs's recursive watch, and keeps each change it is told, by its path in the folder: a panel
-- shows the last ones, and watcher.seen gives them. watcher_c does the same in C.

local ecs = require("ecs")
local fs = require("fs")
local draw = require("draw")

local root = "" -- the watched folder, ending with a slash
local watch = nil
local seen = {} -- the changes since the watch began, such as "a/b/note.txt:added"
local last = {} -- the last changes, for the panel

ecs.event.declare("changed", "The watched folder changed")

-- the folder that a change comes with is the watched folder and the folder inside it, ending with a slash; an empty name is the folder itself,
-- with "overflow" or "gone"
local function changed(folder, name, change)
  local line = folder:sub(#root + 1) .. name .. ":" .. change
  seen[#seen + 1] = line
  table.insert(last, 1, line)
  last[21] = nil
  ecs.event.emit("watcher.changed")
end

local function start(folder)
  if watch then
    watch:stop()
  end
  seen, last = {}, {}
  root = folder
  -- true: the folders inside are watched too, apart from those whose names start with a dot
  local made, reason = fs.watch(folder, changed, true)
  if not made then
    return false, ecs.fail(reason)
  end
  watch = made
  return true
end

-- frees watches, each with its Lua callback, while a call into C through the FFI runs: LuaJIT may collect right after such a call returns,
-- before its wrapper goes on, so a watch's Destroy, which releases its Lua callback, runs there (OpenECS DESIGN 10.6). A line hook stands for
-- that moment, in the wrapper of draw.font, a C function that calls no Lua, which the interpreter runs: it lets go of a watch and collects at
-- one of the wrapper's lines in each call, and at each line in turn, so one of them comes after the call
local function collectInCalls(folder)
  local wrapper = "=draw.font"
  local lines, at = {}, nil
  local watch = nil
  jit.off()
  debug.sethook(function(_, line)
    if debug.getinfo(2, "S").source ~= wrapper then
      return
    end
    lines[#lines + 1] = at == nil and line or nil
    if line == at then
      watch = nil
      collectgarbage()
    end
  end, "l")
  draw.font("ui")
  for _, line in ipairs(lines) do
    at = line
    watch = assert(fs.watch(folder, function() end, false), "the folder is watched")
    draw.font("ui")
  end
  debug.sethook()
  jit.on()
  assert(watch == nil and #lines > 0, "each watch was let go in the wrapper")
end

ecs.service.register({
  start = {
    sig = "bool(string folder, out string error)",
    doc = "Watches a folder and the folders inside it, in place of the folder it watched",
    fn = start,
  },
  seen = {
    sig = "void(int first, out value<string[]> seen)",
    doc = "Gives the changes since the watch began, from the first-th on, each the entry's path in the folder and the change, such as a/note.txt:added",
    fn = function(first)
      return { unpack(seen, first) }
    end,
  },
  collectInCalls = {
    sig = "void(string folder)",
    doc = "Watches a folder and lets go of the watch, again and again, and has Lua's collector free the watches while a call into C through the FFI runs",
    fn = collectInCalls,
  },
})

ecs.panel.registerType({
  name = "panel",
  title = "Changes",
  redrawOn = { "watcher.changed" },
  create = function(panel)
    return { panel = panel }
  end,
  draw = function(_, surface)
    surface:fill(0, 0, surface.width, surface.height, "panel")
    local font = draw.font("ui")
    draw.text(surface, font, root == "" and "Nothing is watched" or "The last changes, newest first:", 12, 12, 16, "text")
    for i, line in ipairs(last) do
      draw.text(surface, font, line, 12, 16 + 22 * i, 16, "text")
    end
  end,
})
