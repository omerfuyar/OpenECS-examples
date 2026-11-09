-- each panel writes its table in its format, reads the text back and writes it again, which gives the same text
return {
  preset = "preset.lua",
  run = function(test)
    local panels = test.session().workspaces[1].windows[1].panels

    test.match(panels, {
      {
        state = {
          format = "Json",
          same = true,
          text = '{\n    "dark": true,\n    "name": "Paint",\n    "scale": 1.5,\n    "size": {\n        "height": 600,\n        "width": 800\n    },\n'
            .. '    "tools": [\n        "brush",\n        "eraser"\n    ]\n}',
          -- the trailing comma is allowed; the second } is not
          problem = "JSON, at line 1, column 21: unexpected content after document",
        },
      },
      { state = { format = "Toml", same = true, text = 'dark = true\nname = "Paint"\nscale = 1.5\ntools = ["brush", "eraser"]\n\n[size]\nheight = 600\nwidth = 800\n' } },
      { state = { format = "Ini", same = true, text = "name = Paint\n\n[size]\nheight = 600\nwidth = 800\n" } },
      { state = { format = "Env", same = true, text = 'GREETING="Hello, world"\nNAME=Paint\n' } },
      { state = { format = "Csv", same = true, text = 'tool,key\nbrush,B\n"eraser, soft",E\n' } },
    }, "the panels' texts")
  end,
}
