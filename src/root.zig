const std = @import("std");

const Chip8 = struct {
    registers: [16]u8,
    memory: [4096]u8,
    index: u16,
    pc: u16,
    stack: [16]u16,
    sp: *u8,
    delay_timer: u8,
    sound_timer: u8,
    keypad: [16]bool,
    displaybuffer: [64 * 32]bool,
    opcode: u16,
};

const START_ADDRESS: u16 = 0x200;

pub fn read_file(allocator: std.mem.Allocator) ![]u8 {
    const cwd = std.fs.cwd();
    const file = try cwd.openFile("foo.txt", .{ .mode = .read_only });
    defer file.close();

    return try file.readToEndAlloc(allocator, 8192);
}
