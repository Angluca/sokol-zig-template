// sokol implementation library on non-Apple platforms
#define SOKOL_IMPL
#if defined(_WIN32)
#define SOKOL_D3D11
#elif defined(__EMSCRIPTEN__)
#define SOKOL_GLES3
#elif defined(__APPLE__)
// NOTE: on macOS, sokol.c is compiled explicitely as ObjC
#define SOKOL_METAL
/*#define SOKOL_GLCORE33*/
#else
#define SOKOL_GLCORE33
#endif

#if !defined(__ANDROID__)
    #define SOKOL_NO_ENTRY
#endif
#if defined(_WIN32)
    #define SOKOL_WIN32_FORCE_MAIN
#endif
// FIXME: macOS Zig HACK without this, some C stdlib headers throw errors
#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#include "sokol.h"
/*#include "sokol_app.h"*/
/*#include "sokol_gfx.h"*/
/*#include "sokol_log.h"*/
/*#include "sokol_glue.h"*/
/*#define CIMGUI_DEFINE_ENUMS_AND_STRUCTS*/
/*#include "cimgui.h"*/
/*#define SOKOL_IMGUI_IMPL*/
/*#include "sokol_imgui.h"*/
