const std = @import("std");
const sk = @cImport({
    @cInclude("sokol.h");
    @cInclude("shaders/quad.glsl.h");
});
const print = std.debug.print;

var pip: sk.sg_pipeline = .{};
var bind: sk.sg_bindings = .{};
var pass_action: sk.sg_pass_action = .{};

export fn init() void {
    sk.sg_setup(&sk.sg_desc{
        .context = sk.sapp_sgcontext(),
        .logger = .{.func = sk.slog_func},
    });
    const vertices = [_]f32 {
        // positions       // colors
        -0.5,  0.5, 0.5,     1.0, 0.0, 0.0, 1.0,
         0.5,  0.5, 0.5,     0.0, 1.0, 0.0, 1.0,
         0.5, -0.5, 0.5,     0.0, 0.0, 1.0, 1.0,
        -0.5, -0.5, 0.5,     1.0, 1.0, 0.0, 1.0,
    };
    const vbuf = sk.sg_make_buffer(&sk.sg_buffer_desc{
        .data = sk.SG_RANGE(vertices),
        .label = "cube-vertices"
    });
    const indices = [_]u16 {
        0, 1, 2,  0, 2, 3,
    };
    const ibuf = sk.sg_make_buffer(&sk.sg_buffer_desc{
        .type = sk.SG_BUFFERTYPE_INDEXBUFFER,
        .data = sk.SG_RANGE(indices),
        .label = "quad-indices",
    });

    bind.vertex_buffers[0] = vbuf;
    bind.index_buffer = ibuf;

    const shd = sk.sg_make_shader(sk.quad_shader_desc(sk.sg_query_backend()));
    var pip_desc: sk.sg_pipeline_desc = .{
        .shader = shd,
        .index_type = sk.SG_INDEXTYPE_UINT16,
        .label = "quad-pipline",
    };

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
    sk.sg_draw(0, 6, 1);
    sk.sg_end_pass();
    sk.sg_commit();
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
            .width = 400,
            .height = 300,
            .window_title = "Quad (sokol-app)",
            .icon = .{
                .sokol_default = true,
            },
            .logger = .{
                .func = sk.slog_func,
            },
        },
    );
}

