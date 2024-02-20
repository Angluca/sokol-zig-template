const std = @import("std");
const sk = @cImport({
    @cInclude("sokol.h");
    @cInclude("shaders/shapes-transform.glsl.h");
});
const print = std.debug.print;
const assert = std.debug.assert;

var pip: sk.sg_pipeline = .{};
var bind: sk.sg_bindings = .{};
var pass_action: sk.sg_pass_action = .{};
var rx: f32 = 0;
var ry: f32 = 0;
var vs_params: sk.vs_params_t = .{};
var vbuf: sk.sg_buffer = .{};
var ibuf: sk.sg_buffer = .{};
var elms: sk.sshape_element_range_t = undefined;

export fn init() void {
    sk.sg_setup(&sk.sg_desc{
        .context = sk.sapp_sgcontext(),
        .logger = .{.func = sk.slog_func},
    });
    var sdt = sk.sdtx_desc_t{.logger = .{.func = sk.slog_func}};
    sdt.fonts[0] = sk.sdtx_font_oric();
    sk.sdtx_setup(&sdt);

    const shd = sk.sg_make_shader(sk.shapes_shader_desc(sk.sg_query_backend()));
    var pip_desc: sk.sg_pipeline_desc = .{
        .shader = shd,
        .index_type = sk.SG_INDEXTYPE_UINT16,
        .cull_mode = sk.SG_CULLMODE_NONE,
        .depth = .{
            .compare = sk.SG_COMPAREFUNC_LESS_EQUAL,
            .write_enabled = true,
        }
    };
    pip_desc.layout.buffers[0] = sk.sshape_vertex_buffer_layout_state();
    pip_desc.layout.attrs[0] = sk.sshape_position_vertex_attr_state();
    pip_desc.layout.attrs[1] = sk.sshape_normal_vertex_attr_state();
    pip_desc.layout.attrs[2] = sk.sshape_texcoord_vertex_attr_state();
    pip_desc.layout.attrs[3] = sk.sshape_color_vertex_attr_state();
    pip = sk.sg_make_pipeline(&pip_desc);

    const vertices: [6 * 1024]sk.sshape_vertex_t = undefined;
    const indices: [16 * 1024]u16 = undefined;
    var buf = sk.sshape_buffer_t {
        .vertices = .{.buffer = sk.SSHAPE_RANGE(vertices)},
        .indices = .{.buffer = sk.SSHAPE_RANGE(indices)},
    };
    const box_transform = sk.HMM_Translate(sk.HMM_Vec3(-1,0,1));
    const sphere_transform = sk.HMM_Translate(sk.HMM_Vec3(1,0,1));
    const cylinder_transform = sk.HMM_Translate(sk.HMM_Vec3(-1,0,-1));
    const torus_transform = sk.HMM_Translate(sk.HMM_Vec3(1,0,-1));

    buf = sk.sshape_build_box(&buf, &sk.sshape_box_t{
        .width = 1.0,
        .height = 1.0,
        .depth = 1.0,
        .tiles = 10,
        .random_colors = true,
        .transform = sk.sshape_mat4(&box_transform.Elements[0][0])
    });
    buf = sk.sshape_build_sphere(&buf, &sk.sshape_sphere_t{
        .merge = true,
        .radius = 0.75,
        .slices = 36,
        .stacks = 20,
        .random_colors = true,
        .transform = sk.sshape_mat4(&sphere_transform.Elements[0][0])
    });
    buf = sk.sshape_build_cylinder(&buf, &sk.sshape_cylinder_t{
        .merge = true,
        .radius = 0.5,
        .height = 1.5,
        .slices = 36,
        .stacks = 10,
        .random_colors = true,
        .transform = sk.sshape_mat4(&cylinder_transform.Elements[0][0])
    });
    buf = sk.sshape_build_torus(&buf, &sk.sshape_torus_t{
        .merge = true,
        .radius = 0.5,
        .ring_radius = 0.3,
        .rings = 36,
        .sides = 18,
        .random_colors = true,
        .transform = sk.sshape_mat4(&torus_transform.Elements[0][0])
    });
    assert(buf.valid);

    // extract element range for sg_draw()
    elms = sk.sshape_element_range(&buf);

    // and finally create the vertex- and index-buffer
    vbuf = sk.sg_make_buffer(&sk.sshape_vertex_buffer_desc(&buf));
    ibuf = sk.sg_make_buffer(&sk.sshape_index_buffer_desc(&buf));
    bind.vertex_buffers[0] = vbuf;
    bind.index_buffer = ibuf;

    pass_action.colors[0] = .{
        .load_action = sk.SG_LOADACTION_CLEAR,
        .clear_value = .{ .r = 0.2, .g = 0.2, .b = 0.2, .a = 1 },
    };
    print("Backend: {}\n", .{sk.sg_query_backend()});
}

export fn frame() void {
    const w = sk.sapp_widthf();
    const h = sk.sapp_heightf();
    const t = @as(f32, @floatCast(sk.sapp_frame_duration() * 60.0));
    sk.sdtx_canvas(w * 0.5, h * 0.5);
    sk.sdtx_pos(0.5, 0.5);
    sk.sdtx_puts("press key to switch draw mode:\n\n" ++
        "  1: vertex normals\n" ++
        "  2: texture coords\n" ++
        "  3: vertex color");
    const proj = sk.HMM_Perspective(60.0, w/h, 0.01, 10.0);
    const view = sk.HMM_LookAt(sk.HMM_Vec3(0.0, 1.5, 6.0), sk.HMM_Vec3(0.0, 0.0, 0.0), sk.HMM_Vec3(0.0, 1.0, 0.0));
    const view_proj = sk.HMM_MultiplyMat4(proj, view);
    rx += 1.0 * t; ry += 2.0 * t;
    const rxm = sk.HMM_Rotate(rx, sk.HMM_Vec3(1.0, 0.0, 0.0));
    const rym = sk.HMM_Rotate(ry, sk.HMM_Vec3(0.0, 1.0, 0.0));
    const model = sk.HMM_MultiplyMat4(rxm, rym);
    vs_params.mvp = sk.HMM_MultiplyMat4(view_proj, model);

    sk.sg_begin_default_pass(&pass_action, @intFromFloat(w), @intFromFloat(h));
    sk.sg_apply_pipeline(pip);
    sk.sg_apply_bindings(&bind);
    sk.sg_apply_uniforms(sk.SG_SHADERSTAGE_VS, sk.SLOT_vs_params, &sk.SG_RANGE(vs_params));
    sk.sg_draw(elms.base_element, elms.num_elements, 1);
    sk.sdtx_draw();
    sk.sg_end_pass();
    sk.sg_commit();
}

export fn input(event: ?*const sk.sapp_event) void {
    const ev = event.?;
    if(ev.type == sk.SAPP_EVENTTYPE_KEY_DOWN) {
        switch(ev.key_code) {
            sk.SAPP_KEYCODE_1 => vs_params.draw_mode = 0.0,
            sk.SAPP_KEYCODE_2 => vs_params.draw_mode = 1.0,
            sk.SAPP_KEYCODE_3 => vs_params.draw_mode = 2.0,
            else => {},
        }
    }
}

export fn cleanup() void {
    sk.sdtx_shutdown();
    sk.sg_shutdown();
}

pub fn main() void {
    sk.sapp_run(
        &sk.sapp_desc {
            .init_cb = init,
            .frame_cb = frame,
            .cleanup_cb = cleanup,
            .event_cb = input,
            .width = 400,
            .height = 300,
            .sample_count = 4,
            .window_title = "shapes-transform (sokol-app)",
            .icon = .{ .sokol_default = true, },
            .logger = .{ .func = sk.slog_func, },
        },
    );
}

