const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const zhip8 = @import("zhip8");
const input = @import("input.zig");

const FB_LEN: usize = @as(usize, zhip8.VIDEO_WIDTH) * @as(usize, zhip8.VIDEO_HEIGHT);

const Model = struct {
    fb: []const bool,
    const KeyEvent = struct { key: vaxis.Key, pressed: bool };

    pub fn widget(self: *Model) vxfw.Widget {
        return .{
            .userdata = self,
            .eventHandler = Model.typeErasedEventHandler,
            .drawFn = Model.typeErasedDrawFn,
        };
    }

    fn reset_keys() void {
        for (input.keymap) |entry| {
            zhip8.chip_key(entry.chip, false);
        }
    }

    fn typeErasedEventHandler(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
        const self: *Model = @ptrCast(@alignCast(ptr));
        switch (event) {
            .init => try ctx.tick(1, self.widget()),
            .tick => {
                for (0..20) |_| { // Hack to run the emulator at ~60Hz
                    zhip8.chip_step();
                }
                ctx.redraw = true;
                try ctx.tick(1, self.widget());
            },
            .key_press => |key| {
                reset_keys();
                if (key.matches(vaxis.Key.escape, .{}) or key.matches('c', .{ .ctrl = true })) {
                    ctx.quit = true;
                    return;
                }
            },
            .key_release => {},
            else => {},
        }

        const key_event: ?KeyEvent = switch (event) {
            .key_press => |key| .{ .key = key, .pressed = true },
            .key_release => |key| .{ .key = key, .pressed = false },
            else => null,
        };
        if (key_event) |ke| {
            inline for (input.keymap) |entry| {
                if (ke.key.matches(entry.cp, entry.mods)) {
                    zhip8.chip_key(entry.chip, ke.pressed);
                    break;
                }
            }
        }
    }

    fn typeErasedDrawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
        const self: *Model = @ptrCast(@alignCast(ptr));
        const on_cell: vaxis.Cell = .{
            .char = .{ .grapheme = "█", .width = 1 },
        };
        const off_cell: vaxis.Cell = .{
            .char = .{ .grapheme = " ", .width = 1 },
        };

        var surface = try vxfw.Surface.init(ctx.arena, self.widget(), .{
            .width = zhip8.VIDEO_WIDTH,
            .height = zhip8.VIDEO_HEIGHT,
        });
        for (self.fb, 0..) |v, i| {
            surface.buffer[i] = if (v) on_cell else off_cell;
        }
        return surface;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    zhip8.chip_init();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len >= 2) {
        const rom_path = args[1];
        const rom_data = try std.fs.cwd().readFileAlloc(allocator, rom_path, 1024 * 1024);
        defer allocator.free(rom_data);
        zhip8.chip_load(@intFromPtr(rom_data.ptr), rom_data.len);
    }

    const fb_ptr = zhip8.chip_fb_ptr();
    const fb = @as([*]const bool, @ptrFromInt(fb_ptr))[0..FB_LEN];

    var app = try vxfw.App.init(allocator);
    defer app.deinit();

    const model = try allocator.create(Model);
    defer allocator.destroy(model);

    model.* = .{
        .fb = fb,
    };

    try app.run(model.widget(), .{});
}
