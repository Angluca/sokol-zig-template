const std = @import("std");
const sk = @cImport({
    @cInclude("sokol.h");
});

var pass_action: sk.sg_pass_action = undefined;

export fn init() void {
    sk.sg_setup(&sk.sg_desc{
        .context = sk.sapp_sgcontext(),
    });
    pass_action = sk.sg_pass_action {
    };
    pass_action.colors[0] = .{
        .load_action = sk.SG_LOADACTION_CLEAR,
        .clear_value = .{ .r = 1, .g = 1, .b = 0, .a = 1 },
    };
}

export fn frame() void {
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
             .window_title = "clear example",
         },
     );
}

