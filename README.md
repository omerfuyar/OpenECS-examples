# OpenECS-examples

Examples for writing [OpenECS](https://github.com/omerfuyar/OpenECS) plugins, one part at a time. Read them in the order of their numbers: each explains the parts that it is the first to use.

- `1_hello` to `12_sketch` teach OpenECS: panels, native plugins, settings, services, keys, events, saved state, drag and drop, typed text, popups, and a whole tool in C and in Lua.
- From `13_terminal`, each teaches standard plugins of [OpenECS-std](https://github.com/omerfuyar/OpenECS-std): `13_terminal` tty, `14_media` image and audio, `15_network` net, `16_model` gltf, and `17_files` fs with Lua's `io`.

Each example holds a preset, `preset.lua`, its plugins and its tests. OpenECS ships the examples in `examples/`, next to the program. Run one with `--fresh`, so it starts from its preset even if you keep sessions (`ecs.keepSession`):

``` shell
./OpenECS --fresh --preset examples/1_hello/preset.lua
```

`12_sketch` shows two plugins that do the same things, `sketch_c` in C and `sketch_lua` in Lua, so their code can be compared: workspace 1 holds the C canvas, workspace 2 the Lua canvas, and workspace 3 both. Draw with the mouse; the wheel changes the brush size. On a canvas, Ctrl+C and Ctrl+V copy and paste strokes, also between the two plugins, Ctrl+B opens a canvas beside, Ctrl+G gathers every canvas, Ctrl+E exports an image and Delete clears. Shift and a drag carry a canvas's strokes to another canvas, and a canvas takes strokes files dropped from a file manager. Ctrl+Tab switches workspace.

## Building and testing

This repository is a submodule of OpenECS, in its `examples/` folder. OpenECS's build, with `--examples`, compiles and runs `shuild.c`, which copies each example into `bin/examples/` and builds its plugins there. Build and test inside a checkout of OpenECS:

``` shell
git clone --recursive https://github.com/omerfuyar/OpenECS.git
cd OpenECS
.github/scripts/build.sh D
.github/scripts/test.sh build/Debug/bin/OpenECS examples
```

## Releases

This repository is released with OpenECS and OpenECS-std, at the same time and with the same version. Each release has a description in `.github/release-notes/`.
