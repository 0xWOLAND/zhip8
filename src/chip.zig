const std = @import("std");
const Ops = @import("ops.zig").Ops;
const dispatch = @import("ops.zig").dispatch;

pub const Chip8 = struct {
    registers: [16]u8,
    memory: [4096]u8,
    index: u16,
    pc: u16,
    stack: [16]u16,
    sp: u8,
    delay_timer: u8,
    sound_timer: u8,
    keypad: [16]bool,
    displaybuffer: [64 * 32]bool,
    opcode: u16,

    rng: std.Random.DefaultPrng,

    pub fn init() Chip8 {
        const FONT_ADDRESS = @import("constants.zig").FONT_ADDRESS;
        const FONTSET_SIZE = @import("constants.zig").FONTSET_SIZE;
        const FONTSET = @import("constants.zig").FONTSET;

        return Chip8{
            .registers = [_]u8{0} ** 16,
            .memory = blk: {
                var mem = [_]u8{0} ** 4096;
                mem[FONT_ADDRESS .. FONT_ADDRESS + FONTSET_SIZE].* =
                    FONTSET[0..FONTSET_SIZE].*;
                break :blk mem;
            },
            .index = 0,
            .pc = @import("constants.zig").START_ADDRESS,
            .stack = [_]u16{0} ** 16,
            .sp = 0,
            .delay_timer = 0,
            .sound_timer = 0,
            .keypad = [_]bool{false} ** 16,
            .displaybuffer = [_]bool{false} ** (64 * 32),
            .opcode = 0,
            .rng = std.Random.DefaultPrng.init(blk: {
                var seed: u64 = 0;
                _ = std.posix.getrandom(std.mem.asBytes(&seed)) catch {};
                break :blk seed;
            }),
        };
    }

    pub fn load_program(self: *Chip8, allocator: std.mem.Allocator) !void {
        const cwd = std.fs.cwd();
        const file = try cwd.openFile("foo.txt", .{ .mode = .read_only });
        defer file.close();

        const buf = try file.readToEndAlloc(allocator, 8192);
        const len = buf.len;

        @memcpy(self.memory[@import("constants.zig").START_ADDRESS..][0..len], buf);
    }

    pub fn step(self: *Chip8) !void {
        self.opcode =
            (@as(u16, self.memory[self.pc]) << 8) |
            @as(u16, self.memory[self.pc + 1]);

        self.pc += 2;

        const idx: usize = @intCast((self.opcode & 0xF000) >> 12);
        try dispatch[idx](self);

        if (self.delay_timer > 0) self.delay_timer -= 1;
        if (self.sound_timer > 0) self.sound_timer -= 1;
    }
};
