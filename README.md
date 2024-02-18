Not need generated binding file, Use origin [sokol headers](https://github.com/floooh/sokol) directly.

For Zig version 0.12.0-dev and newer.

## Building the samples

Supported platforms are: Windows, macOS, Linux (with X11) and web

On Linux install the following packages: libglu1-mesa-dev, mesa-common-dev, xorg-dev, libasound-dev
(or generally: the dev packages required for X11, GL and ALSA development)

To build the platform-native samples:

```sh
# build and run project:
zig build
zig build run

# build and run example:
zig build -Dexample
zig build -Dexample clear
zig build -Dexample triangle
zig build -Dexample quad
zig build -Dexample bufferoffsets
zig build -Dexample cube
zig build -Dexample noninterleaved
zig build -Dexample texcube
zig build -Dexample offscreen
zig build -Dexample instancing
zig build -Dexample mrt
zig build -Dexample saudio
zig build -Dexample sgl
zig build -Dexample sgl-context
zig build -Dexample sgl-points
zig build -Dexample debugtext
zig build -Dexample debugtext-print
zig build -Dexample debugtext-userfont
zig build -Dexample shapes
```

(also run ```zig build --help``` to inspect the build targets)

By default, the backend 3D API will be selected based on the target platform:

- macOS: Metal
- Windows: D3D11
- Linux: GL

To force the GL backend on macOS or Windows, build with ```-Dgl=true```:

```
> zig build -Dgl=true run-clear
```

The ```clear``` sample prints the selected backend to the terminal:

```
sokol-zig ➤ zig build -Dgl=true run-clear
Backend: .sokol.gfx.Backend.GLCORE33
```

For the web-samples, run:

```sh
zig build -Dtarget=wasm32-emscripten
# or to build and run one of the samples
zig build run-clear -Dtarget=wasm32-emscripten
...
```

When building with target `wasm32-emscripten` for the first time, the build script will
install and activate the Emscripten SDK into the Zig package cache for the latest SDK
version. There is currently no build system functionality to update or delete the Emscripten SDK
after this first install. The current workaround is to delete the global Zig cache
(run `zig env` to see where the Zig cache resides).

Improving the Emscripten SDK integration with the Zig build system is planned for the future.

Generite glsl to zig shaders file
```sh
zig build shaders
# or build example shaders
zig build shaders -Dexample
```
