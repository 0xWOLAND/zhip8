const Chip8 = @import("chip.zig").Chip8;
const std = @import("std");

pub const Ops = struct {
    // 0x00E0: Clear the display
    fn OP_00E0(chip: *Chip8) void {
        @memset(chip.displaybuffer[0..], false);
    }

    // 0x00EE: Return from a subroutine
    fn OP_00EE(chip: *Chip8) !void {
        if (chip.sp == 0) {
            return error.StackUnderflow;
        }
        chip.sp -= 1;
        chip.pc = chip.stack[chip.sp];
    }

    // 0x1NNN: Jump to address NNN
    fn OP_1NNN(chip: *Chip8, op: u16) void {
        chip.pc = op & 0x0FFF;
    }

    // 0x2NNN: Call subroutine at NNN
    fn OP_2NNN(chip: *Chip8, op: u16) !void {
        if (chip.sp >= 16) {
            return error.StackOverflow;
        }
        chip.stack[chip.sp] = chip.pc;
        chip.sp += 1;
        chip.pc = op & 0x0FFF;
    }

    // 0x3XKK: Skip next instruction if Vx == KK
    fn OP_3XKK(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const kk: u8 = @intCast(op & 0x00FF);
        if (chip.registers[vx] == kk)
            chip.pc += 2;
    }

    // 0x4XKK: Skip next instruction if Vx != KK
    fn OP_4XKK(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const kk: u8 = @intCast(op & 0x00FF);
        if (chip.registers[vx] != kk)
            chip.pc += 2;
    }

    // 0x5XY0: Skip next instruction if Vx == Vy
    fn OP_5XY0(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const vy = (op & 0x00F0) >> 4;
        if (chip.registers[vx] == chip.registers[vy])
            chip.pc += 2;
    }

    // 0x6XKK: Set Vx = KK
    fn OP_6XKK(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const kk: u8 = @intCast(op & 0x00FF);
        chip.registers[vx] = kk;
    }

    // 0x7XKK: Set Vx = Vx + KK
    fn OP_7XKK(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const kk: u8 = @intCast(op & 0x00FF);
        chip.registers[vx] += kk;
    }

    // 0x8XY0: Set Vx = Vy
    fn OP_8XY0(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const vy = (op & 0x00F0) >> 4;
        chip.registers[vx] = chip.registers[vy];
    }

    // 0x8XY1: Set Vx = Vx OR Vy
    fn OP_8XY1(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const vy = (op & 0x00F0) >> 4;
        chip.registers[vx] |= chip.registers[vy];
    }

    // 0x8XY2: Set Vx = Vx AND Vy
    fn OP_8XY2(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const vy = (op & 0x00F0) >> 4;
        chip.registers[vx] &= chip.registers[vy];
    }

    // 0x8XY3: Set Vx = Vx XOR Vy
    fn OP_8XY3(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const vy = (op & 0x00F0) >> 4;
        chip.registers[vx] ^= chip.registers[vy];
    }

    // 0x8XY4: Set Vx = Vx + Vy, set VF = carry
    fn OP_8XY4(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const vy = (op & 0x00F0) >> 4;
        const sum = @addWithOverflow(chip.registers[vx], chip.registers[vy]);
        chip.registers[vx] = @intCast(sum[0]);
        chip.registers[0xF] = sum[1];
    }

    // 0x8XY5: Set Vx = Vx - Vy, set VF = NOT borrow
    fn OP_8XY5(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const vy = (op & 0x00F0) >> 4;
        const diff = @subWithOverflow(chip.registers[vx], chip.registers[vy]);
        chip.registers[vx] = @intCast(diff[0]);
        chip.registers[0xF] = diff[1];
    }

    // 0x8XY6: Set Vx = Vx SHR 1
    fn OP_8XY6(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        chip.registers[0xF] = chip.registers[vx] & 0x1;
        chip.registers[vx] >>= 1;
    }

    // 0x8XY7: Set Vx = Vy - Vx, set VF = NOT borrow
    fn OP_8XY7(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const vy = (op & 0x00F0) >> 4;
        const diff = @subWithOverflow(chip.registers[vy], chip.registers[vx]);
        chip.registers[vx] = @intCast(diff[0]);
        chip.registers[0xF] = diff[1];
    }

    // 0x8XYE: Set Vx = Vx SHL 1
    fn OP_8XYE(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        chip.registers[0xF] = (chip.registers[vx] & 0x80) >> 7;
        chip.registers[vx] <<= 1;
    }

    // 0x9XY0: Skip next instruction if Vx != Vy
    fn OP_9XY0(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const vy = (op & 0x00F0) >> 4;
        if (chip.registers[vx] != chip.registers[vy])
            chip.pc += 2;
    }

    // 0xANNN: Set I = NNN
    fn OP_ANNN(chip: *Chip8, op: u16) void {
        chip.index = op & 0x0FFF;
    }

    // 0xBNNN: Jump to address NNN + V0
    fn OP_BNNN(chip: *Chip8, op: u16) void {
        chip.pc = (op & 0x0FFF) + @as(u16, chip.registers[0]);
    }

    // 0xCXKK: Set Vx = random byte AND KK
    fn OP_CXKK(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const kk: u8 = @intCast(op & 0x00FF);
        const rand_byte = chip.rng.random().int(u8);
        chip.registers[vx] = rand_byte & kk;
    }

    // 0xDXYN: Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision
    fn OP_DXYN(chip: *Chip8, op: u16) void {
        const vx: u8 = @intCast(chip.registers[(op & 0x0F00) >> 8]);
        const vy: u8 = @intCast(chip.registers[(op & 0x00F0) >> 4]);
        const height: u8 = @intCast(op & 0x000F);
        chip.registers[0xF] = 0;

        const VIDEO_WIDTH = @import("constants.zig").VIDEO_WIDTH;
        const VIDEO_HEIGHT = @import("constants.zig").VIDEO_HEIGHT;

        for (0..height) |y| {
            const sprite = chip.memory[chip.index + y];

            for (0..8) |x| {
                const shift: u3 = @intCast(x);
                const mask = @as(u8, 0x80) >> shift;
                if ((sprite & mask) == 0) continue;

                const idx =
                    (@as(usize, (vy + y) & (VIDEO_HEIGHT - 1)) * VIDEO_WIDTH) +
                    (@as(usize, (vx + x) & (VIDEO_WIDTH - 1)));

                if (chip.displaybuffer[idx]) chip.registers[0xF] = 1;
                chip.displaybuffer[idx] = !chip.displaybuffer[idx];
            }
        }
    }

    // 0xEX9E: Skip next instruction if key with the value of Vx is pressed
    fn OP_EX9E(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const key = chip.registers[vx];
        if (chip.keypad[key]) {
            chip.pc += 2;
        }
    }

    // 0xEXA1: Skip next instruction if key with the value of Vx is not pressed
    fn OP_EXA1(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const key = chip.registers[vx];
        if (!chip.keypad[key]) {
            chip.pc += 2;
        }
    }

    // 0xFX07: Set Vx = delay timer value
    fn OP_FX07(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        chip.registers[vx] = @as(u8, chip.delay_timer);
    }

    // 0xFX0A: Wait for a key press, store the value of the key in Vx
    fn OP_FX0A(chip: *Chip8, op: u16) void {
        const vx: usize = @intCast((op & 0x0F00) >> 8);

        for (0..16) |i| {
            const key: u8 = @intCast(i);

            if (chip.keypad[i]) {
                chip.registers[vx] = key;
                return;
            }
        }

        chip.pc -= 2;
    }

    // 0xFX15: Set delay timer = Vx
    fn OP_FX15(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        chip.delay_timer = chip.registers[vx];
    }

    // 0xFX18: Set sound timer = Vx
    fn OP_FX18(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        chip.sound_timer = chip.registers[vx];
    }

    // 0xFX1E: Set I = I + Vx
    fn OP_FX1E(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        chip.index += @as(u16, chip.registers[vx]);
    }

    // 0xFX29: Set I = location of sprite for digit Vx
    fn OP_FX29(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const digit = chip.registers[vx];
        chip.index = @import("constants.zig").FONT_ADDRESS + (@as(u16, digit) * 5);
    }

    // 0xFX33: Store BCD representation of Vx in memory locations I, I+1, and I+2
    fn OP_FX33(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        const value = chip.registers[vx];
        chip.memory[chip.index] = value / 100;
        chip.memory[chip.index + 1] = (value / 10) % 10;
        chip.memory[chip.index + 2] = value % 10;
    }

    // 0xFX55: Store registers V0 through Vx in memory starting at location I
    fn OP_FX55(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        var i: u16 = 0;
        while (i <= vx) : (i += 1) {
            chip.memory[chip.index + i] = chip.registers[i];
        }
    }

    // 0xFX65: Read registers V0 through Vx from memory starting at location I
    fn OP_FX65(chip: *Chip8, op: u16) void {
        const vx = (op & 0x0F00) >> 8;
        var i: u16 = 0;
        while (i <= vx) : (i += 1) {
            chip.registers[i] = chip.memory[chip.index + i];
        }
    }
};

const OpFn = fn (chip: *Chip8) void;

const Rule = struct {
    mask: u16,
    value: u16,
    func: OpFn,
};

const rules = [_]Rule{
    .{ 0xFFFF, 0x00E0, Ops.OP_00E0 },
    .{ 0xFFFF, 0x00EE, Ops.OP_00EE },

    .{ 0xF000, 0x1000, Ops.OP_1NNN },
    .{ 0xF000, 0x2000, Ops.OP_2NNN },
    .{ 0xF000, 0x3000, Ops.OP_3XKK },
    .{ 0xF000, 0x4000, Ops.OP_4XKK },
    .{ 0xF00F, 0x5000, Ops.OP_5XY0 },
    .{ 0xF000, 0x6000, Ops.OP_6XKK },
    .{ 0xF000, 0x7000, Ops.OP_7XKK },

    .{ 0xF00F, 0x8000, Ops.OP_8XY0 },
    .{ 0xF00F, 0x8001, Ops.OP_8XY1 },
    .{ 0xF00F, 0x8002, Ops.OP_8XY2 },
    .{ 0xF00F, 0x8003, Ops.OP_8XY3 },
    .{ 0xF00F, 0x8004, Ops.OP_8XY4 },
    .{ 0xF00F, 0x8005, Ops.OP_8XY5 },
    .{ 0xF00F, 0x8006, Ops.OP_8XY6 },
    .{ 0xF00F, 0x8007, Ops.OP_8XY7 },
    .{ 0xF00F, 0x800E, Ops.OP_8XYE },

    .{ 0xF00F, 0x9000, Ops.OP_9XY0 },

    .{ 0xF000, 0xA000, Ops.OP_ANNN },
    .{ 0xF000, 0xB000, Ops.OP_BNNN },
    .{ 0xF000, 0xC000, Ops.OP_CXKK },
    .{ 0xF000, 0xD000, Ops.OP_DXYN },

    .{ 0xF0FF, 0xE09E, Ops.OP_EX9E },
    .{ 0xF0FF, 0xE0A1, Ops.OP_EXA1 },

    .{ 0xF0FF, 0xF007, Ops.OP_FX07 },
    .{ 0xF0FF, 0xF00A, Ops.OP_FX0A },
    .{ 0xF0FF, 0xF015, Ops.OP_FX15 },
    .{ 0xF0FF, 0xF018, Ops.OP_FX18 },
    .{ 0xF0FF, 0xF01E, Ops.OP_FX1E },
    .{ 0xF0FF, 0xF029, Ops.OP_FX29 },
    .{ 0xF0FF, 0xF033, Ops.OP_FX33 },
    .{ 0xF0FF, 0xF055, Ops.OP_FX55 },
    .{ 0xF0FF, 0xF065, Ops.OP_FX65 },
};

pub const dispatch = blk: {
    const illegal: OpFn = struct {
        fn f(_: *Chip8) void {
            @panic("Illegal opcode");
        }
    }.f;

    var table = [_]OpFn{illegal} ** 0x10000;

    for (rules) |r| {
        for (0..table.len) |i| {
            const opcode: u16 = @intCast(i);
            if ((opcode & r.mask) == r.value) {
                table[i] = r.func;
            }
        }
    }

    break :blk table;
};
