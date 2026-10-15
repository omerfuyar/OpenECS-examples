# OpenECS-examples

Examples for writing [OpenECS](https://github.com/omerfuyar/OpenECS) plugins, one part at a time. Read them in the order of their numbers: each explains the parts that it is the first to use.

- `1_hello` to `12_sketch` teach OpenECS: panels, native plugins, settings, services, keys, events, saved state, drag and drop, typed text, popups, and a whole tool in C and in Lua.
- From `13_terminal`, each teaches standard plugins of [OpenECS-std](https://github.com/omerfuyar/OpenECS-std): `13_terminal` textgrid, `14_media` the loaders image and audio with draw and mixer, `15_network` net over TCP and UDP, `16_model` gltf with draw's lines, `17_files` fs with Lua's `io`, and `18_web` web's HTTP and HTTPS requests and WebSocket connections, from a page and an echo server that it serves itself with net. `3_ui` already shows ui's controls, in Lua and, on its second workspace, in C with ui's macros.
- `19_first_party` shows a tool with the first-party plugins that every tool can have: the settings window, the panel list and the launcher, and tests the themes.
- `20_workers` shows workers: Lua scripts that run on threads of their own, here four that count primes at once while the panel stays free.
- `21_gpu` shows GPU panels, which draw into a texture on the GPU that shows in any window the panel moves to: a plugin in Lua draws with the gpu standard plugin, and one in C with SDL's GPU API itself.
- `22_gpu_model` draws a glTF model filled and lit on the GPU: gltf reads its vertices, normals and triangles, Lua turns and lights them, and gpu draws them as one mesh. Drag to turn it.

Each example holds a preset, `preset.lua`, its plugins and its tests. The examples are the tests of OpenECS and its standard plugins too: each test checks what its example shows. OpenECS ships the examples in `examples/`, next to the program. Run one with `--fresh`, so it starts from its preset even if you keep sessions (`ecs.keepSession`):

``` shell
./OpenECS --fresh --preset examples/1_hello/preset.lua
```

`12_sketch` shows two plugins that do the same things, `sketch_c` in C and `sketch_lua` in Lua, so their code can be compared: workspace 1 holds the C canvas, workspace 2 the Lua canvas, and workspace 3 both. Draw with the mouse; the wheel changes the brush size. On a canvas, Ctrl+C and Ctrl+V copy and paste strokes, also between the two plugins, Ctrl+B opens a canvas beside, Ctrl+G gathers every canvas, Ctrl+E exports an image and Delete clears. Shift and a drag carry a canvas's strokes to another canvas, and a canvas takes strokes files dropped from a file manager. Ctrl+Tab switches workspace.

Each example's plugins declare their names without the plugin's own name: `name = "greeting"` in the plugin `hello` registers `hello.greeting`. The build writes a `.luarc.json` here, so an editor with LuaLS completes `require("ui")` and the other plugins' functions.

## Building and testing

This repository is a submodule of OpenECS, in its `examples/` folder. OpenECS's build, with `--examples`, compiles and runs `shuild.c`, which copies each example into `bin/examples/` and builds its plugins there. A second build compiles only the plugins whose files changed. Build and test inside a checkout of OpenECS:

``` shell
git clone --recursive https://github.com/omerfuyar/OpenECS.git
cd OpenECS
.github/scripts/build.sh D
.github/scripts/test.sh build/Debug/bin/OpenECS
```

## Releases

This repository is released with OpenECS and OpenECS-std, at the same time and with the same version. Each release has a description in `.github/release-notes/`.
