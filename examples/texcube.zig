const std = @import("std");
const sk = @cImport({
    @cInclude("sokol.h");
    @cInclude("shaders/texcube.glsl.h");
});
const print = std.debug.print;

var pip: sk.sg_pipeline = .{};
var bind: sk.sg_bindings = .{};
var pass_action: sk.sg_pass_action = .{};
var rx: f32 = 0;
var ry: f32 = 0;
const Vertex = struct {
    f32, f32, f32,
    u32, i16, i16
};

export fn init() void {
    sk.sg_setup(&sk.sg_desc{
        .context = sk.sapp_sgcontext(),
        .logger = .{.func = sk.slog_func},
    });
    const vertices = [_]Vertex {
         // pos               color       uvs
        .{ -1.0, -1.0, -1.0,  0xFF0000FF,     0,     0 },
        .{  1.0, -1.0, -1.0,  0xFF0000FF, 32767,     0 },
        .{  1.0,  1.0, -1.0,  0xFF0000FF, 32767, 32767 },
        .{ -1.0,  1.0, -1.0,  0xFF0000FF,     0, 32767 },

        .{ -1.0, -1.0,  1.0,  0xFF00FF00,     0,     0 },
        .{  1.0, -1.0,  1.0,  0xFF00FF00, 32767,     0 },
        .{  1.0,  1.0,  1.0,  0xFF00FF00, 32767, 32767 },
        .{ -1.0,  1.0,  1.0,  0xFF00FF00,     0, 32767 },

        .{ -1.0, -1.0, -1.0,  0xFFFF0000,     0,     0 },
        .{ -1.0,  1.0, -1.0,  0xFFFF0000, 32767,     0 },
        .{ -1.0,  1.0,  1.0,  0xFFFF0000, 32767, 32767 },
        .{ -1.0, -1.0,  1.0,  0xFFFF0000,     0, 32767 },

        .{  1.0, -1.0, -1.0,  0xFFFF007F,     0,     0 },
        .{  1.0,  1.0, -1.0,  0xFFFF007F, 32767,     0 },
        .{  1.0,  1.0,  1.0,  0xFFFF007F, 32767, 32767 },
        .{  1.0, -1.0,  1.0,  0xFFFF007F,     0, 32767 },

        .{ -1.0, -1.0, -1.0,  0xFFFF7F00,     0,     0 },
        .{ -1.0, -1.0,  1.0,  0xFFFF7F00, 32767,     0 },
        .{  1.0, -1.0,  1.0,  0xFFFF7F00, 32767, 32767 },
        .{  1.0, -1.0, -1.0,  0xFFFF7F00,     0, 32767 },

        .{ -1.0,  1.0, -1.0,  0xFF007FFF,     0,     0 },
        .{ -1.0,  1.0,  1.0,  0xFF007FFF, 32767,     0 },
        .{  1.0,  1.0,  1.0,  0xFF007FFF, 32767, 32767 },
        .{  1.0,  1.0, -1.0,  0xFF007FFF,     0, 32767 },
    };
    const vbuf = sk.sg_make_buffer(&sk.sg_buffer_desc{
        .data = sk.SG_RANGE(vertices),
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
    });
    bind.vertex_buffers[0] = vbuf;
    bind.index_buffer = ibuf;
    // create a checkerboard texture
    const pixels = [_]u32 {
        0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
        0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
        0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
        0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
    };
    // NOTE: SLOT_tex is provided by shader code generation
    var image: sk.sg_image_desc = .{
        .width = 4,
        .height = 4,
    };
    image.data.subimage[0][0] = sk.SG_RANGE(pixels);
    bind.fs.images[sk.SLOT_tex] = sk.sg_make_image(&image);
    bind.fs.samplers[sk.SLOT_smp] = sk.sg_make_sampler(&sk.sg_sampler_desc{});

    const shd = sk.sg_make_shader(sk.texcube_shader_desc(sk.sg_query_backend()));
    var pip_desc: sk.sg_pipeline_desc = .{
        .shader = shd,
        .index_type = sk.SG_INDEXTYPE_UINT16,
        .cull_mode = sk.SG_CULLMODE_BACK,
        .depth = .{
            .compare = sk.SG_COMPAREFUNC_LESS_EQUAL,
            .write_enabled = true,
        }
    };

    //pip_desc.layout.buffers[0].stride = 28;
    pip_desc.layout.attrs[0].format = sk.SG_VERTEXFORMAT_FLOAT3;
    pip_desc.layout.attrs[1].format = sk.SG_VERTEXFORMAT_UBYTE4N;
    pip_desc.layout.attrs[2].format = sk.SG_VERTEXFORMAT_SHORT2N;
    pip = sk.sg_make_pipeline(&pip_desc);

    pass_action.colors[0] = .{
        .load_action = sk.SG_LOADACTION_CLEAR,
        .clear_value = .{ .r = 0.2, .g = 0.5, .b = 0, .a = 1 },
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

    const b = pass_action.colors[0].clear_value.b + 0.01;
    pass_action.colors[0].clear_value.b = if(b > 1.0) 0.0 else b;

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
            .window_title = "texture (sokol-app)",
            .icon = .{
                .sokol_default = true,
            },
            .logger = .{
                .func = sk.slog_func,
            },
        },
    );
}

