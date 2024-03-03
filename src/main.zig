const std = @import("std");
const sk = @cImport({
    //@cInclude("sokol.h");
    @cInclude("sokol_app.h");
    @cInclude("sokol_gfx.h");
    @cInclude("sokol_glue.h");
    @cInclude("sokol_log.h");
    @cInclude("shaders/main.glsl.h");
});
const hm = @cImport({
    //@cDefine("HANDMADE_MATH_IMPLEMENTATION", {});
    //@cDefine("HANDMADE_MATH_NO_SSE", {});
    @cInclude("HandmadeMath.h");
});
const print = std.debug.print;

var pip: sk.sg_pipeline = .{};
var bind: sk.sg_bindings = .{};
var pass_action: sk.sg_pass_action = .{};

export fn init() void {
    const testVec = hm.HMM_Vec3(0.1, 1.0, 1.1);
    print("vec = {any}\n", .{testVec.Elements});

    sk.sg_setup(&sk.sg_desc{
        .context = sk.sapp_sgcontext(),
        .logger = .{.func = sk.slog_func},
    });
    const vertices = [_]f32 {
        // positions    // colors
        0.0, 0.5, 0.5,  1.0, 0.0, 0.0, 1.0,
        0.5,-0.5, 0.5,  0.0, 1.0, 0.0, 1.0,
       -0.5,-0.5, 0.5,  0.0, 0.0, 1.0, 1.0,
    };
    bind.vertex_buffers[0] = sk.sg_make_buffer(&sk.sg_buffer_desc{
        .data = sk.SG_RANGE(vertices),
        .label = "triangle-vertices"
    });
    const shd = sk.sg_make_shader(sk.main_shader_desc(sk.sg_query_backend()));
    var pip_desc: sk.sg_pipeline_desc = .{.shader = shd};
    pip_desc.layout.attrs[sk.ATTR_vs_position].format = sk.SG_VERTEXFORMAT_FLOAT3;
    pip_desc.layout.attrs[sk.ATTR_vs_color0].format = sk.SG_VERTEXFORMAT_FLOAT4;
    pip = sk.sg_make_pipeline(&pip_desc);

    pass_action.colors[0] = .{
        .load_action = sk.SG_LOADACTION_CLEAR,
        .clear_value = .{ .r = 0.2, .g = 0.5, .b = 0, .a = 1 },
    };
    print("Backend: {}\n", .{sk.sg_query_backend()});
}

export fn frame() void {
    const b = pass_action.colors[0].clear_value.b + 0.01;
    pass_action.colors[0].clear_value.b = if(b > 1.0) 0.0 else b;

    sk.sg_begin_default_pass(&pass_action, sk.sapp_width(), sk.sapp_height());
    sk.sg_apply_pipeline(pip);
    sk.sg_apply_bindings(&bind);
    sk.sg_draw(0, 3, 1);
    sk.sg_end_pass();
    sk.sg_commit();
}

export fn event(e: ?*const sk.sapp_event) void {
    const ev = e.?;
    if(ev.type == sk.SAPP_EVENTTYPE_KEY_DOWN) {
        switch(ev.key_code) {
            sk.SAPP_KEYCODE_ESCAPE => sk.sapp_quit(),
            else => |keycode| print("{any} ",.{keycode}),
        }
    }
}

export fn cleanup() void {
    sk.sg_shutdown();
}

pub fn main() void {
    sk.sapp_run(
        &sk.sapp_desc {
            .init_cb = init,
            .frame_cb = frame,
            .cleanup_cb = cleanup,
            .event_cb = event,
            .width = 400,
            .height = 300,
            .window_title = "main (sokol-app)",
            .icon = .{
                .sokol_default = true,
            },
            .logger = .{
                .func = sk.slog_func,
            },
        },
    );
}

