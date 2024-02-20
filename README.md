Not need generated binding file, Use origin [sokol headers](https://github.com/floooh/sokol) directly.

For Zig version 0.12.0-dev or newer.

## Building the samples

Supported platforms are: Windows, macOS, Linux (with X11) and web

On Linux install the following packages: libglu1-mesa-dev, mesa-common-dev, xorg-dev, libasound-dev
(or generally: the dev packages required for X11, GL and ALSA development)

sokol.h: You can use it add headers
```c
// sokol.h
#include "sokol_app.h"
#include "sokol_gfx.h"
 ... and more
#include "nuklear.h"
```

Add headers dictionary and build c files in build.zig
```zig
var user_h_dirs = .{
    "src/lib",
};
var user_c_files = .{
    "src/lib/nuklear.c",
};
```

To build the platform-native samples:

```sh
# First generite glsl to h shaders file if use glsl
zig build shaders
# or build example shaders
zig build shaders -Dexample
```
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
zig build -Dexample shapes
zig build -Dexample shapes-transform
zig build -Dexample offscreen
zig build -Dexample offscreen-msaa
zig build -Dexample instancing
zig build -Dexample mrt
zig build -Dexample mrt-pixelformats
zig build -Dexample arraytex
zig build -Dexample tex3d
zig build -Dexample dyntex
zig build -Dexample basisu
zig build -Dexample cubemap-jpeg
zig build -Dexample cubemaprt
zig build -Dexample miprender
zig build -Dexample layerrender
zig build -Dexample primtypes
zig build -Dexample uvwrap
zig build -Dexample mipmap
zig build -Dexample uniformtypes
zig build -Dexample blend
zig build -Dexample sdf
zig build -Dexample shadows
zig build -Dexample shadows-depthtex
zig build -Dexample imgui
zig build -Dexample imgui-dock
zig build -Dexample imgui-highdpi
zig build -Dexample cimgui
zig build -Dexample imgui-images
zig build -Dexample imgui-usercallback
zig build -Dexample nuklear
zig build -Dexample nuklear-images
zig build -Dexample sgl-microui
zig build -Dexample fontstash
zig build -Dexample fontstash-layers
zig build -Dexample debugtext
zig build -Dexample debugtext-printf
zig build -Dexample debugtext-userfont
zig build -Dexample debugtext-context
zig build -Dexample debugtext-layers
zig build -Dexample events
zig build -Dexample icon
zig build -Dexample droptest
zig build -Dexample pixelformats
zig build -Dexample drawcallperf
zig build -Dexample saudio
zig build -Dexample modplay
zig build -Dexample noentry
zig build -Dexample restart
zig build -Dexample sgl
zig build -Dexample sgl-lines
zig build -Dexample sgl-points
zig build -Dexample sgl-context
zig build -Dexample loadpng
zig build -Dexample plmpeg
zig build -Dexample cgltf
zig build -Dexample ozz-anim
zig build -Dexample ozz-skin
zig build -Dexample shdfeatures
zig build -Dexample spine-simple
zig build -Dexample spine-inspector
zig build -Dexample spine-layers
zig build -Dexample spine-skinsets
zig build -Dexample spine-switch-skinsets
zig build -Dexample spine-contexts
```

(also run ```zig build --help``` to inspect the build targets)

By default, the backend 3D API will be selected based on the target platform:

- macOS: Metal
- Windows: D3D11
- Linux: GL

To force the GL backend on macOS or Windows, build with ```-Dgl=true```:

```
> zig build -Dgl=true -Dexample clear
```

The ```clear``` sample prints the selected backend to the terminal:

```
sokol-zig ➤ zig build -Dgl=true -Dexample clear
Backend: .sokol.gfx.Backend.GLCORE33
```

For the web-samples, run:

```sh
zig build -Dtarget=wasm32-emscripten
# or to build and run one of the samples
zig build clear -Dexample -Dtarget=wasm32-emscripten
...
```

When building with target `wasm32-emscripten` for the first time, the build script will
install and activate the Emscripten SDK into the Zig package cache for the latest SDK
version. There is currently no build system functionality to update or delete the Emscripten SDK
after this first install. The current workaround is to delete the global Zig cache
(run `zig env` to see where the Zig cache resides).

Improving the Emscripten SDK integration with the Zig build system is planned for the future.

