-- Ctrl+E exports a canvas as a PPM image, to a file that the system's save dialog chooses; a test answers that dialog itself

local folder = debug.getinfo(1, "S").source:match("^@(.*[/\\])")

return {
  preset = "preset.lua",
  run = function(test)
    test.call("ecs.workspace.switch2")
    local canvas = test.rect(test.session().workspaces[2].windows[1][1].panels[1].id)
    test.drag(canvas.x + 50, canvas.y + 60, canvas.x + 200, canvas.y + 150)

    -- the Lua canvas asks with ecs.dialog.show, which does not wait; while a test runs, the dialog waits for test.fileDialog
    test.key("Ctrl+E")
    test.match(test.fileDialog(), { type = "saveFile", location = "canvas.ppm", many = false, filters = { { name = "PPM images", pattern = "ppm" } } }, "the export dialog")

    -- an empty list cancels the dialog, as the user does, and nothing is written
    test.fileDialog({})
    test.match(test.fileDialog(), nil, "no dialog after the answer")

    -- a list of paths answers it: the canvas's function gets them, and writes the image there
    local path = folder .. "exported.ppm"
    os.remove(path)
    test.key("Ctrl+E")
    test.fileDialog({ path })
    local file = assert(io.open(path, "rb"), "the image is written")
    local header = file:read(2)
    file:close()
    os.remove(path)
    test.match(header, "P6", "the image is a PPM")
  end,
}
