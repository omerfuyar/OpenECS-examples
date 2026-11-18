# Sketch help

[Sketch](https://github.com/omerfuyar/OpenECS-examples) is a tool for **quick drawings**. Its canvas keeps *every* stroke, and the session keeps the canvas; ~~nothing~~ no stroke is lost.

## Keys

| Key    | Does                  |
| ------ | --------------------- |
| Delete | Clears the canvas     |
| Ctrl+E | Exports a PNG file    |
| Ctrl+C | Copies the strokes    |

## Getting started

1. Press on the canvas and drag.
2. Turn the wheel to change the brush.
3. Right-click a tab for its menu.

- [x] Draw a stroke
- [ ] Export it

> The brush's colour is the setting `sketch_lua.brushColor`, so the settings window changes it.

```lua
ecs.setting.set("sketch_lua.brushColor", "green")
```

---

See [OpenECS](https://github.com/omerfuyar/OpenECS) and [its standard plugins](https://github.com/omerfuyar/OpenECS-std) for more.
