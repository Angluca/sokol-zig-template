const std = @import("std");
const sk = @cImport({
    @cInclude("sokol.h");
    @cInclude("shaders/bufferoffsets.glsl.h");
});
const print = std.debug.print;

var pip: sk.sg_pipeline = .{};
var bind: sk.sg_bindings = .{};
var pass_action: sk.sg_pass_action = .{};
const Vertex = struct {
    f32,f32,f32,f32,f32
};

export fn init() void {
    sk.sg_setup(&sk.sg_desc{
        .context = sk.sapp_sgcontext(),
        .logger = .{.func = sk.slog_func},
    });
    const vertices = [_]Vertex {
        // triangle
        .{  0.0,   0.55,  1.0, 0.0, 0.0 },
        .{  0.25,  0.05,  0.0, 1.0, 0.0 },
        .{ -0.25,  0.05,  0.0, 0.0, 1.0 },

        // quad
        .{ -0.25, -0.05,  0.0, 0.0, 1.0 },
        .{  0.25, -0.05,  0.0, 1.0, 0.0 },
        .{  0.25, -0.55,  1.0, 0.0, 0.0 },
        .{ -0.25, -0.55,  1.0, 1.0, 0.0 }
    };
    const indices = [_]u16 {
        0, 1, 2,
        0, 1, 2, 0, 2, 3
    };

    const vbuf = sk.sg_make_buffer(&sk.sg_buffer_desc{
        .data = sk.SG_RANGE(vertices),
        .label = "buffer-vertices"
    });
    const ibuf = sk.sg_make_buffer(&sk.sg_buffer_desc{
        .type = sk.SG_BUFFERTYPE_INDEXBUFFER,
        .data = sk.SG_RANGE(indices),
        .label = "buffer-indices",
    });

    bind.vertex_buffers[0] = vbuf;
    bind.index_buffer = ibuf;

    const shd = sk.sg_make_shader(sk.bufferoffsets_shader_desc(sk.sg_query_backend()));
    var pip_desc: sk.sg_pipeline_desc = .{
        .shader = shd,
        .index_type = sk.SG_INDEXTYPE_UINT16,
        .label = "buffer-pipline",
    };

    pip_desc.layout.attrs[0].format = sk.SG_VERTEXFORMAT_FLOAT2;
    pip_desc.layout.attrs[1].format = sk.SG_VERTEXFORMAT_FLOAT3;
    pip = sk.sg_make_pipeline(&pip_desc);

    pass_action.colors[0] = .{
        .load_action = sk.SG_LOADACTION_CLEAR,
        .clear_value = .{ .r = 0.5, .g = 0.5, .b = 1, .a = 1 },
    };
    print("Backend: {}\n", .{sk.sg_query_backend()});
}

export fn frame() void {
    sk.sg_begin_default_pass(&pass_action, sk.sapp_width(), sk.sapp_height());
    sk.sg_apply_pipeline(pip);
    // render the triangle
    bind.vertex_buffer_offsets[0] = 0;
    bind.index_buffer_offset = 0;
    sk.sg_apply_bindings(&bind);
    sk.sg_draw(0, 3, 1);
    // render the quad
    bind.vertex_buffer_offsets[0] = 3 * @sizeOf(Vertex);
    bind.index_buffer_offset = 3 * @sizeOf(u16);
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
            .window_title = "Buffer Offsets (sokol-app)",
            .icon = .{
                .sokol_default = true,
            },
            .logger = .{
                .func = sk.slog_func,
            },
        },
    );
}

