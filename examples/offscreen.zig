const std = @import("std");
const sk = @cImport({
    @cInclude("sokol.h");
    @cInclude("shaders/offscreen.glsl.h");
});
const print = std.debug.print;
const assert = std.debug.assert;

const offscreen_sample_count = 1;

const Offscreen = struct {
    pass_action: sk.sg_pass_action = .{},
    pass: sk.sg_pass = .{},
    pip: sk.sg_pipeline = .{},
    bind: sk.sg_bindings = .{},
};
const Default = struct {
    pass_action: sk.sg_pass_action = .{},
    pip: sk.sg_pipeline = .{},
    bind: sk.sg_bindings = .{},
};
var offscreen: Offscreen = .{};
var default: Default = .{};
var donut: sk.sshape_element_range_t = .{};
var sphere: sk.sshape_element_range_t = .{};
var rx: f32 = 0;
var ry: f32 = 0;

export fn init() void {
    sk.sg_setup(&sk.sg_desc{
        .context = sk.sapp_sgcontext(),
        .logger = .{.func = sk.slog_func},
    });

    default.pass_action.colors[0] = .{
        .load_action = sk.SG_LOADACTION_CLEAR,
        .clear_value = .{ .r = 0.25, .g = 0.45, .b = 0.65, .a = 1 },
    };
    offscreen.pass_action.colors[0] = .{
        .load_action = sk.SG_LOADACTION_CLEAR,
        .clear_value = .{ .r = 0.25, .g = 0.25, .b = 0.25, .a = 1 },
    };

    var img_desc: sk.sg_image_desc = .{
        .render_target = true,
        .width = 256,
        .height = 256,
        .pixel_format = sk.SG_PIXELFORMAT_RGBA8,
        .sample_count = offscreen_sample_count,
    };
    const color_img = sk.sg_make_image(&img_desc);
    img_desc.pixel_format = sk.SG_PIXELFORMAT_DEPTH;
    const depth_img = sk.sg_make_image(&img_desc);

    var pass_desc: sk.sg_pass_desc = .{};
    pass_desc.color_attachments[0].image = color_img;
    pass_desc.depth_stencil_attachment.image = depth_img;
    offscreen.pass = sk.sg_make_pass(&pass_desc);

    const vertices: [4000]sk.sshape_vertex_t = undefined;
    const indices: [24000]u16 = undefined;
    var buf: sk.sshape_buffer_t = sk.sshape_buffer_t {
        .vertices = .{.buffer = sk.SSHAPE_RANGE(vertices)},
        .indices = .{.buffer = sk.SSHAPE_RANGE(indices)},
    };

    buf = sk.sshape_build_torus(&buf, &sk.sshape_torus_t{
        .radius = 0.5,
        .ring_radius = 0.3,
        .sides = 20,
        .rings = 36,
    });
    donut = sk.sshape_element_range(&buf);
    buf = sk.sshape_build_sphere(&buf, &sk.sshape_sphere_t{
        .radius = 0.5,
        .slices = 72,
        .stacks = 40,
    });
    sphere = sk.sshape_element_range(&buf);

    const vbuf = sk.sg_make_buffer(&sk.sshape_vertex_buffer_desc(&buf));
    const ibuf = sk.sg_make_buffer(&sk.sshape_index_buffer_desc(&buf));

    // offscreen.pip
    var offscreen_pip_desc = sk.sg_pipeline_desc {
        .shader = sk.sg_make_shader(sk.offscreen_shader_desc(sk.sg_query_backend())),
        .index_type = sk.SG_INDEXTYPE_UINT16,
        .cull_mode = sk.SG_CULLMODE_BACK,
        .sample_count = offscreen_sample_count,
        .depth = .{
            .pixel_format = sk.SG_PIXELFORMAT_DEPTH,
            .compare = sk.SG_COMPAREFUNC_LESS_EQUAL,
            .write_enabled = true,
        },
    };
    offscreen_pip_desc.colors[0].pixel_format = sk.SG_PIXELFORMAT_RGBA8;
    offscreen_pip_desc.layout.buffers[0] = sk.sshape_vertex_buffer_layout_state();
    offscreen_pip_desc.layout.attrs[sk.ATTR_vs_offscreen_position] = sk.sshape_position_vertex_attr_state();
    offscreen_pip_desc.layout.attrs[sk.ATTR_vs_offscreen_normal] = sk.sshape_normal_vertex_attr_state();
    offscreen.pip = sk.sg_make_pipeline(&offscreen_pip_desc);

    // default.pip
    var default_pip_desc = sk.sg_pipeline_desc {
        .shader = sk.sg_make_shader(sk.default_shader_desc(sk.sg_query_backend())),
        .index_type = sk.SG_INDEXTYPE_UINT16,
        .cull_mode = sk.SG_CULLMODE_BACK,
        .depth = .{
            .compare = sk.SG_COMPAREFUNC_LESS_EQUAL,
            .write_enabled = true,
        }
    };
    default_pip_desc.layout.buffers[0] = sk.sshape_vertex_buffer_layout_state();
    default_pip_desc.layout.attrs[sk.ATTR_vs_default_position] = sk.sshape_position_vertex_attr_state();
    default_pip_desc.layout.attrs[sk.ATTR_vs_default_normal] = sk.sshape_normal_vertex_attr_state();
    default_pip_desc.layout.attrs[sk.ATTR_vs_default_texcoord0] = sk.sshape_texcoord_vertex_attr_state();
    default.pip = sk.sg_make_pipeline(&default_pip_desc);

    const smp = sk.sg_make_sampler(&sk.sg_sampler_desc{
        .min_filter = sk.SG_FILTER_LINEAR,
        .mag_filter = sk.SG_FILTER_LINEAR,
        .wrap_u = sk.SG_WRAP_REPEAT,
        .wrap_v = sk.SG_WRAP_REPEAT,
    });

    offscreen.bind.vertex_buffers[0] = vbuf;
    offscreen.bind.index_buffer = ibuf;

    default.bind.vertex_buffers[0] = vbuf;
    default.bind.index_buffer = ibuf;

    default.bind.fs.images[sk.SLOT_tex] = color_img;
    default.bind.fs.samplers[sk.SLOT_smp] = smp;
    print("\n--Backend: {}\n", .{sk.sg_query_backend()});
}

fn computeMvp(rxn: f32, ryn: f32, aspect: f32, eye_dist: f32) sk.hmm_mat4 {
    const proj = sk.HMM_Perspective(45.0, aspect, 0.01, 10.0);
    const view = sk.HMM_LookAt(sk.HMM_Vec3(0, 0, eye_dist), sk.HMM_Vec3(0.0, 0.0, 0.0), sk.HMM_Vec3(0.0, 1.0, 0.0));
    const view_proj = sk.HMM_MultiplyMat4(proj, view);
    const rxm = sk.HMM_Rotate(rxn, sk.HMM_Vec3(1.0, 0.0, 0.0));
    const rym = sk.HMM_Rotate(ryn, sk.HMM_Vec3(0.0, 1.0, 0.0));
    const model = sk.HMM_MultiplyMat4(rxm, rym);
    return sk.HMM_MultiplyMat4(view_proj, model);
}
export fn frame() void {
    const dt: f32 = @floatCast(sk.sapp_frame_duration() * 60.0);
    rx += 1.0 * dt; ry += 2.0 * dt;

    var vs_params: sk.vs_params_t = .{};
    // the offscreen pass, rendering an rotating, untextured donut into a render target image
    vs_params = .{.mvp = computeMvp(rx, ry, 1.0, 2.5)};
    sk.sg_begin_pass(offscreen.pass, &offscreen.pass_action);
    sk.sg_apply_pipeline(offscreen.pip);
    sk.sg_apply_bindings(&offscreen.bind);
    sk.sg_apply_uniforms(sk.SG_SHADERSTAGE_VS, sk.SLOT_vs_params, &sk.SG_RANGE(vs_params));
    sk.sg_draw(donut.base_element, donut.num_elements, 1);
    sk.sg_end_pass();

    // and the default-pass, rendering a rotating textured sphere which uses the
    // previously rendered offscreen render-target as texture
    const aspect = sk.sapp_widthf()/sk.sapp_heightf();
    vs_params = .{.mvp = computeMvp(-rx * 0.25, ry * 0.25, aspect, 2.0)};
    sk.sg_begin_default_pass(&default.pass_action, sk.sapp_width(), sk.sapp_height());
    sk.sg_apply_pipeline(default.pip);
    sk.sg_apply_bindings(&default.bind);
    sk.sg_apply_uniforms(sk.SG_SHADERSTAGE_VS, sk.SLOT_vs_params, &sk.SG_RANGE(vs_params));
    sk.sg_draw(sphere.base_element, sphere.num_elements, 1);
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
            .window_title = "Offscreen Rendering (sokol-app)",
            .icon = .{ .sokol_default = true, },
            .logger = .{ .func = sk.slog_func, },
        },
    );
}

