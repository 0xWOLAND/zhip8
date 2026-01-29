const Chip = @import("chip.zig").Chip8;
const std = @import("std");
const constants = @import("constants.zig");

pub const VIDEO_WIDTH = constants.VIDEO_WIDTH;
pub const VIDEO_HEIGHT = constants.VIDEO_HEIGHT;

var chip: Chip = undefined;

pub export fn chip_init() void {
    chip = Chip.init();
}

pub export fn chip_step() void {
    _ = chip.step() catch {
        @panic("Chip8 step error");
    };
}

pub export fn chip_load(ptr: usize, len: usize) void {
    const buf = @as([*]const u8, @ptrFromInt(ptr))[0..len];
    _ = chip.load_program(buf);
}

pub export fn chip_key(key: u8, pressed: bool) void {
    if (key < 16) {
        chip.keypad[@as(usize, key)] = pressed;
    }
}

pub export fn chip_fb_ptr() usize {
    return @intFromPtr(&chip.displaybuffer);
}
