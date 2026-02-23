const Chip8 = @import("chip.zig").Chip8;
const std = @import("std");

pub const Ops = struct {
    // 0x00E0: Clear the display
    fn OP_00E0(chip: *Chip8) !void {
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
    fn OP_1NNN(chip: *Chip8) !void {
        chip.pc = chip.opcode & 0x0FFF;
    }

    // 0x2NNN: Call subroutine at NNN
    fn OP_2NNN(chip: *Chip8) !void {
        if (chip.sp >= 16) {
            return error.StackOverflow;
        }
        chip.stack[chip.sp] = chip.pc;
        chip.sp += 1;
        chip.pc = chip.opcode & 0x0FFF;
    }

    // 0x3XKK: Skip next instruction if Vx == KK
    fn OP_3XKK(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const kk: u8 = @intCast(chip.opcode & 0x00FF);
        if (chip.registers[vx] == kk)
            chip.pc += 2;
    }

    // 0x4XKK: Skip next instruction if Vx != KK
    fn OP_4XKK(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const kk: u8 = @intCast(chip.opcode & 0x00FF);
        if (chip.registers[vx] != kk)
            chip.pc += 2;
    }

    // 0x5XY0: Skip next instruction if Vx == Vy
    fn OP_5XY0(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const vy = (chip.opcode & 0x00F0) >> 4;
        if (chip.registers[vx] == chip.registers[vy])
            chip.pc += 2;
    }

    // 0x6XKK: Set Vx = KK
    fn OP_6XKK(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const kk: u8 = @intCast(chip.opcode & 0x00FF);
        chip.registers[vx] = kk;
    }

    // 0x7XKK: Set Vx = Vx + KK
    fn OP_7XKK(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const kk: u8 = @intCast(chip.opcode & 0x00FF);
        chip.registers[vx] +%= kk;
    }

    // 0x8XY0: Set Vx = Vy
    fn OP_8XY0(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const vy = (chip.opcode & 0x00F0) >> 4;
        chip.registers[vx] = chip.registers[vy];
    }

    // 0x8XY1: Set Vx = Vx OR Vy
    fn OP_8XY1(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const vy = (chip.opcode & 0x00F0) >> 4;
        chip.registers[vx] |= chip.registers[vy];
    }

    // 0x8XY2: Set Vx = Vx AND Vy
    fn OP_8XY2(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const vy = (chip.opcode & 0x00F0) >> 4;
        chip.registers[vx] &= chip.registers[vy];
    }

    // 0x8XY3: Set Vx = Vx XOR Vy
    fn OP_8XY3(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const vy = (chip.opcode & 0x00F0) >> 4;
        chip.registers[vx] ^= chip.registers[vy];
    }

    // 0x8XY4: Set Vx = Vx + Vy, set VF = carry
    fn OP_8XY4(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const vy = (chip.opcode & 0x00F0) >> 4;
        const sum = @addWithOverflow(chip.registers[vx], chip.registers[vy]);
        chip.registers[vx] = @intCast(sum[0]);
        chip.registers[0xF] = sum[1];
    }

    // 0x8XY5: Set Vx = Vx - Vy, set VF = NOT borrow
    fn OP_8XY5(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const vy = (chip.opcode & 0x00F0) >> 4;
        const diff = @subWithOverflow(chip.registers[vx], chip.registers[vy]);
        chip.registers[vx] = @intCast(diff[0]);
        chip.registers[0xF] = if (diff[1] == 0) 1 else 0;
    }

    // 0x8XY6: Set Vx = Vx SHR 1
    fn OP_8XY6(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        chip.registers[0xF] = chip.registers[vx] & 0x1;
        chip.registers[vx] >>= 1;
    }

    // 0x8XY7: Set Vx = Vy - Vx, set VF = NOT borrow
    fn OP_8XY7(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const vy = (chip.opcode & 0x00F0) >> 4;
        const diff = @subWithOverflow(chip.registers[vy], chip.registers[vx]);
        chip.registers[vx] = @intCast(diff[0]);
        chip.registers[0xF] = if (diff[1] == 0) 1 else 0;
    }

    // 0x8XYE: Set Vx = Vx SHL 1
    fn OP_8XYE(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        chip.registers[0xF] = (chip.registers[vx] & 0x80) >> 7;
        chip.registers[vx] <<= 1;
    }

    // 0x9XY0: Skip next instruction if Vx != Vy
    fn OP_9XY0(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const vy = (chip.opcode & 0x00F0) >> 4;
        if (chip.registers[vx] != chip.registers[vy])
            chip.pc += 2;
    }

    // 0xANNN: Set I = NNN
    fn OP_ANNN(chip: *Chip8) !void {
        chip.index = chip.opcode & 0x0FFF;
    }

    // 0xBNNN: Jump to address NNN + V0
    fn OP_BNNN(chip: *Chip8) !void {
        chip.pc = (chip.opcode & 0x0FFF) + @as(u16, chip.registers[0]);
    }

    // 0xCXKK: Set Vx = random byte AND KK
    fn OP_CXKK(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const kk: u8 = @intCast(chip.opcode & 0x00FF);
        const rand_byte = chip.rng.random().int(u8);
        chip.registers[vx] = rand_byte & kk;
    }

    // 0xDXYN: Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision
    fn OP_DXYN(chip: *Chip8) !void {
        const vx: u8 = @intCast(chip.registers[(chip.opcode & 0x0F00) >> 8]);
        const vy: u8 = @intCast(chip.registers[(chip.opcode & 0x00F0) >> 4]);
        const height: u8 = @intCast(chip.opcode & 0x000F);
        chip.registers[0xF] = 0;

        const VIDEO_WIDTH = @import("constants.zig").VIDEO_WIDTH;
        const VIDEO_HEIGHT = @import("constants.zig").VIDEO_HEIGHT;

        for (0..height) |y| {
            const addr: usize = (@as(usize, chip.index) + y) & 0x0FFF;
            const sprite = chip.memory[addr];

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
    fn OP_EX9E(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const key = chip.registers[vx];
        if (key < 16 and chip.keypad[key]) {
            chip.pc += 2;
        }
    }

    // 0xEXA1: Skip next instruction if key with the value of Vx is not pressed
    fn OP_EXA1(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const key = chip.registers[vx];
        if (key >= 16 or !chip.keypad[key]) {
            chip.pc += 2;
        }
    }

    // 0xFX07: Set Vx = delay timer value
    fn OP_FX07(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        chip.registers[vx] = @as(u8, chip.delay_timer);
    }

    // 0xFX0A: Wait for a key press, store the value of the key in Vx
    fn OP_FX0A(chip: *Chip8) !void {
        const vx: usize = @intCast((chip.opcode & 0x0F00) >> 8);

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
    fn OP_FX15(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        chip.delay_timer = chip.registers[vx];
    }

    // 0xFX18: Set sound timer = Vx
    fn OP_FX18(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        chip.sound_timer = chip.registers[vx];
    }

    // 0xFX1E: Set I = I + Vx
    fn OP_FX1E(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        chip.index += @as(u16, chip.registers[vx]);
    }

    // 0xFX29: Set I = location of sprite for digit Vx
    fn OP_FX29(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const digit = chip.registers[vx];
        chip.index = @import("constants.zig").FONT_ADDRESS + (@as(u16, digit) * 5);
    }

    // 0xFX33: Store BCD representation of Vx in memory locations I, I+1, and I+2
    fn OP_FX33(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        const value = chip.registers[vx];
        chip.memory[chip.index] = value / 100;
        chip.memory[chip.index + 1] = (value / 10) % 10;
        chip.memory[chip.index + 2] = value % 10;
    }

    // 0xFX55: Store registers V0 through Vx in memory starting at location I
    fn OP_FX55(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        var i: u16 = 0;
        while (i <= vx) : (i += 1) {
            chip.memory[chip.index + i] = chip.registers[i];
        }
    }

    // 0xFX65: Read registers V0 through Vx from memory starting at location I
    fn OP_FX65(chip: *Chip8) !void {
        const vx = (chip.opcode & 0x0F00) >> 8;
        var i: u16 = 0;
        while (i <= vx) : (i += 1) {
            chip.registers[i] = chip.memory[chip.index + i];
        }
    }
};

fn op0(chip: *Chip8) !void {
    return switch (chip.opcode) {
        0x00E0 => Ops.OP_00E0(chip),
        0x00EE => Ops.OP_00EE(chip),
        // TODO: Implement SCHIP opcodes
        0x0000 => {},
        0x00FB => {},
        0x00FC => {},
        0x00FD => {},
        0x00FE => {},
        0x00FF => {},
        else => {
            std.debug.print("Illegal opcode: 0x{X:0>4}\n", .{chip.opcode});
            return anyerror.IllegalOpcode;
        },
    };
}

fn op8(chip: *Chip8) !void {
    return switch (chip.opcode & 0xF) {
        0x0 => Ops.OP_8XY0(chip),
        0x1 => Ops.OP_8XY1(chip),
        0x2 => Ops.OP_8XY2(chip),
        0x3 => Ops.OP_8XY3(chip),
        0x4 => Ops.OP_8XY4(chip),
        0x5 => Ops.OP_8XY5(chip),
        0x6 => Ops.OP_8XY6(chip),
        0x7 => Ops.OP_8XY7(chip),
        0xE => Ops.OP_8XYE(chip),
        else => {
            std.debug.print("Illegal opcode: 0x{X:0>4}\n", .{chip.opcode});
            return anyerror.IllegalOpcode;
        },
    };
}

fn opE(chip: *Chip8) !void {
    return switch (chip.opcode & 0xFF) {
        0x9E => Ops.OP_EX9E(chip),
        0xA1 => Ops.OP_EXA1(chip),
        else => {
            std.debug.print("Illegal opcode: 0x{X:0>4}\n", .{chip.opcode});
            return anyerror.IllegalOpcode;
        },
    };
}

fn opF(chip: *Chip8) !void {
    return switch (chip.opcode & 0xFF) {
        0x07 => Ops.OP_FX07(chip),
        0x0A => Ops.OP_FX0A(chip),
        0x15 => Ops.OP_FX15(chip),
        0x18 => Ops.OP_FX18(chip),
        0x1E => Ops.OP_FX1E(chip),
        0x29 => Ops.OP_FX29(chip),
        0x33 => Ops.OP_FX33(chip),
        0x55 => Ops.OP_FX55(chip),
        0x65 => Ops.OP_FX65(chip),
        else => {
            std.debug.print("Illegal opcode: 0x{X:0>4}\n", .{chip.opcode});
            return anyerror.IllegalOpcode;
        },
    };
}

pub const dispatch: [16]*const fn (*Chip8) anyerror!void = .{
    &op0,
    &Ops.OP_1NNN,
    &Ops.OP_2NNN,
    &Ops.OP_3XKK,
    &Ops.OP_4XKK,
    &Ops.OP_5XY0,
    &Ops.OP_6XKK,
    &Ops.OP_7XKK,
    &op8,
    &Ops.OP_9XY0,
    &Ops.OP_ANNN,
    &Ops.OP_BNNN,
    &Ops.OP_CXKK,
    &Ops.OP_DXYN,
    &opE,
    &opF,
};

test "test dispatch" {
    var chip = Chip8.init();
    chip.memory[0x200] = 0x60;
    chip.memory[0x201] = 0x0A;

    chip.pc = 0x200;
    chip.step() catch {
        @panic("step failed");
    };
}
