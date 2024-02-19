const std = @import("std");
const sk = @cImport({
    @cInclude("sokol.h");
    @cInclude("shaders/cube.glsl.h");
});
const print = std.debug.print;

var pip: sk.sg_pipeline = .{};
var bind: sk.sg_bindings = .{};
var pass_action: sk.sg_pass_action = .{};
var rx: f32 = 0;
var ry: f32 = 0;

export fn init() void {
    sk.sg_setup(&sk.sg_desc{
        .context = sk.sapp_sgcontext(),
        .logger = .{.func = sk.slog_func},
    });
    const vertices = [_]f32 {
        // positions       // colors
        -1.0, -1.0, -1.0,   1.0, 0.0, 0.0, 1.0,
         1.0, -1.0, -1.0,   1.0, 0.0, 0.0, 1.0,
         1.0,  1.0, -1.0,   1.0, 0.0, 0.0, 1.0,
        -1.0,  1.0, -1.0,   1.0, 0.0, 0.0, 1.0,

        -1.0, -1.0,  1.0,   0.0, 1.0, 0.0, 1.0,
         1.0, -1.0,  1.0,   0.0, 1.0, 0.0, 1.0,
         1.0,  1.0,  1.0,   0.0, 1.0, 0.0, 1.0,
        -1.0,  1.0,  1.0,   0.0, 1.0, 0.0, 1.0,

        -1.0, -1.0, -1.0,   0.0, 0.0, 1.0, 1.0,
        -1.0,  1.0, -1.0,   0.0, 0.0, 1.0, 1.0,
        -1.0,  1.0,  1.0,   0.0, 0.0, 1.0, 1.0,
        -1.0, -1.0,  1.0,   0.0, 0.0, 1.0, 1.0,

        1.0, -1.0, -1.0,    1.0, 0.5, 0.0, 1.0,
        1.0,  1.0, -1.0,    1.0, 0.5, 0.0, 1.0,
        1.0,  1.0,  1.0,    1.0, 0.5, 0.0, 1.0,
        1.0, -1.0,  1.0,    1.0, 0.5, 0.0, 1.0,

        -1.0, -1.0, -1.0,   0.0, 0.5, 1.0, 1.0,
        -1.0, -1.0,  1.0,   0.0, 0.5, 1.0, 1.0,
         1.0, -1.0,  1.0,   0.0, 0.5, 1.0, 1.0,
         1.0, -1.0, -1.0,   0.0, 0.5, 1.0, 1.0,

        -1.0,  1.0, -1.0,   1.0, 0.0, 0.5, 1.0,
        -1.0,  1.0,  1.0,   1.0, 0.0, 0.5, 1.0,
         1.0,  1.0,  1.0,   1.0, 0.0, 0.5, 1.0,
         1.0,  1.0, -1.0,   1.0, 0.0, 0.5, 1.0
    };
    const vbuf = sk.sg_make_buffer(&sk.sg_buffer_desc{
        .data = sk.SG_RANGE(vertices),
        .label = "cube-vertices"
    });
    const indices = [_]u16 {
        0, 1, 2,  0, 2, 3,
        6, 5, 4,  7, 6, 4,
        8, 9, 10,  8, 10, 11,
        14, 13, 12,  15, 14, 12,
        16, 17, 18,  16, 18, 19,
        22, 21, 20,  23, 22, 20
    };
    const ibuf = sk.sg_make_buffer(&sk.sg_buffer_desc{
        .type = sk.SG_BUFFERTYPE_INDEXBUFFER,
        .data = sk.SG_RANGE(indices),
        .label = "cube-indices",
    });

    const shd = sk.sg_make_shader(sk.cube_shader_desc(sk.sg_query_backend()));
    var pip_desc: sk.sg_pipeline_desc = .{
        .shader = shd,
        .index_type = sk.SG_INDEXTYPE_UINT16,
        .cull_mode = sk.SG_CULLMODE_BACK,
        .label = "cube-pipline",
        .depth = .{
            .write_enabled = true,
            .compare = sk.SG_COMPAREFUNC_LESS_EQUAL,
        }
    };

    pip_desc.layout.buffers[0].stride = 28;
    pip_desc.layout.attrs[sk.ATTR_vs_position].format = sk.SG_VERTEXFORMAT_FLOAT3;
    pip_desc.layout.attrs[sk.ATTR_vs_color0].format = sk.SG_VERTEXFORMAT_FLOAT4;
    pip = sk.sg_make_pipeline(&pip_desc);

    bind.vertex_buffers[0] = vbuf;
    bind.index_buffer = ibuf;

    pass_action.colors[0] = .{
        .load_action = sk.SG_LOADACTION_CLEAR,
        .clear_value = .{ .r = 0, .g = 0, .b = 0, .a = 1 },
    };
    print("Backend: {}\n", .{sk.sg_query_backend()});
}

export fn frame() void {
    var vs_params: sk.vs_params_t = .{};
    const w = sk.sapp_widthf();
    const h = sk.sapp_heightf();
    const t = @as(f32, @floatCast(sk.sapp_frame_duration() * 60.0));
    const proj = sk.HMM_Perspective(60.0, w/h, 0.01, 10.0);
    const view = sk.HMM_LookAt(sk.HMM_Vec3(0.0, 1.5, 6.0), sk.HMM_Vec3(0.0, 0.0, 0.0), sk.HMM_Vec3(0.0, 1.0, 0.0));
    const view_proj = sk.HMM_MultiplyMat4(proj, view);
    rx += 1.0 * t; ry += 2.0 * t;
    const rxm = sk.HMM_Rotate(rx, sk.HMM_Vec3(1.0, 0.0, 0.0));
    const rym = sk.HMM_Rotate(ry, sk.HMM_Vec3(0.0, 1.0, 0.0));
    const model = sk.HMM_MultiplyMat4(rxm, rym);
    vs_params.mvp = sk.HMM_MultiplyMat4(view_proj, model);

    const g = pass_action.colors[0].clear_value.g + 0.01;
    pass_action.colors[0].clear_value.g = if(g > 1.0) 0.0 else g;

    sk.sg_begin_default_pass(&pass_action, @intFromFloat(w), @intFromFloat(h));
    sk.sg_apply_pipeline(pip);
    sk.sg_apply_bindings(&bind);
    sk.sg_apply_uniforms(sk.SG_SHADERSTAGE_VS, sk.SLOT_vs_params, &sk.SG_RANGE(vs_params));
    sk.sg_draw(0, 36, 1);
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
            .sample_count = 4,
            .window_title = "cube (sokol-app)",
            .icon = .{
                .sokol_default = true,
            },
            .logger = .{
                .func = sk.slog_func,
            },
        },
    );
}

