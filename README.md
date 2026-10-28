# OpenECS-examples

Examples for writing [OpenECS](https://github.com/omerfuyar/OpenECS) plugins, one part at a time. Read them in the order of their names, the `c` ones first: each explains the parts that it is the first to use.

- `c1_hello` to `c12_sketch` teach OpenECS: panels, native plugins, settings, services, keys, events, saved state, drag and drop, typed text, popups, and a whole tool in C and in Lua. `c13_workers` shows workers: Lua scripts that run on threads of their own, here four that count primes at once while the panel stays free.
- From `s1_terminal`, each teaches standard plugins of [OpenECS-std](https://github.com/omerfuyar/OpenECS-std): `s1_terminal` textgrid, `s2_media` the loaders image and audio with draw and mixer, `s3_network` net over TCP and UDP, `s4_model` gltf with draw's lines, `s5_files` fs with Lua's `io`, and `s6_web` web's HTTP and HTTPS requests and WebSocket connections, from a page and an echo server that it serves itself with net. `c3_ui` already shows ui's controls, in Lua and, on its second workspace, in C with ui's macros.
- `s7_first_party` shows a tool with the first-party plugins that every tool can have: the settings window, the panel list and the launcher, and tests the themes.
- `s8_gpu` shows GPU panels, which draw into a texture on the GPU that shows in any window the panel moves to: a plugin in Lua and one in C draw the same picture with the gpu standard plugin.
- `s9_gpu_model` draws a glTF model on the GPU with shaders of its own: gltf reads its vertices, normals and triangles, which go to the GPU once as buffers, and gpu draws them each frame with a pipeline, cglm's matrices and a depth texture. Its shaders are GLSL, which gpu compiles. Drag to turn it.
- `s10_cglm` shows the cglm plugin, which gives cglm's vectors, matrices and quaternions to Lua: a cube's edges, turned and seen in perspective, drawn with draw. Its second workspace has the same cube in C, with the same functions. Drag to turn it.

Each example holds a preset, `preset.lua`, its plugins and its tests. The examples are the tests of OpenECS and its standard plugins too: each test checks what its example shows. OpenECS ships the examples in `examples/`, next to the program. Run one with `--fresh`, so it starts from its preset even if you keep sessions (`ecs.keepSession`):

``` shell
./OpenECS --fresh --preset examples/c1_hello/preset.lua
```

`c12_sketch` shows two plugins that do the same things, `sketch_c` in C and `sketch_lua` in Lua, so their code can be compared: workspace 1 holds the C canvas, workspace 2 the Lua canvas, and workspace 3 both. Draw with the mouse; the wheel changes the brush size. On a canvas, Ctrl+C and Ctrl+V copy and paste strokes, also between the two plugins, Ctrl+B opens a canvas beside, Ctrl+G gathers every canvas, Ctrl+E exports an image and Delete clears. Shift and a drag carry a canvas's strokes to another canvas, and a canvas takes strokes files dropped from a file manager. Ctrl+Tab switches workspace.

Each example's plugins declare their names without the plugin's own name: `name = "greeting"` in the plugin `hello` registers `hello.greeting`. The build writes a `.luarc.json` here, so an editor with LuaLS completes `require("ui")` and the other plugins' functions.

## Building and testing

This repository is a submodule of OpenECS, in its `examples/` folder. OpenECS's build, with `--examples`, compiles and runs `shuild.c`, which copies each example into `bin/examples/` and builds its plugins there. A second build compiles only the plugins whose files changed. Build and test inside a checkout of OpenECS:

``` shell
git clone --recursive https://github.com/omerfuyar/OpenECS.git
cd OpenECS
gcc shuild.c -o shuild.ignore -O3
./shuild.ignore -t
```

`-t` builds in Debug with the examples, and runs every example's test; `-t c12_sketch` runs one example's tests. OpenECS's README.md says how to run them on Wayland.

## Releases

This repository is released with OpenECS and OpenECS-std, at the same time and with the same version. Each release has a description in `.github/release-notes/`.

Each release also has the examples built for Linux and Windows, with OpenECS of the same version, in `examples/`. Unpack it into an OpenECS folder of that version, and run an example with `./OpenECS --fresh --preset examples/c1_hello/preset.lua`.
