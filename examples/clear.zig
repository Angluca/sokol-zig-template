const std = @import("std");
const sk = @cImport({
    @cInclude("sokol.h");
});
const print = std.debug.print;

var pass_action: sk.sg_pass_action = .{};

export fn init() void {
    sk.sg_setup(&sk.sg_desc{
        .context = sk.sapp_sgcontext(),
        .logger = .{.func = sk.slog_func},
    });
    pass_action.colors[0] = .{
        .load_action = sk.SG_LOADACTION_CLEAR,
        .clear_value = .{ .r = 1, .g = 1, .b = 0, .a = 1 },
    };
    print("Backend: {}\n", .{sk.sg_query_backend()});
}

export fn frame() void {
    const g = pass_action.colors[0].clear_value.g + 0.01;
    pass_action.colors[0].clear_value.g = if(g > 1.0) 0.0 else g;
    sk.sg_begin_default_pass(&pass_action, sk.sapp_width(), sk.sapp_height());
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
            .window_title = "myapp",
            .icon = .{
                .sokol_default = true,
            },
            .logger = .{
                .func = sk.slog_func,
            },
            .win32_console_attach = true,
        },
    );
}

