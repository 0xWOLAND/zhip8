const vaxis = @import("vaxis");

pub const KeyMapEntry = struct {
    cp: u21,
    mods: vaxis.Key.Modifiers = .{},
    chip: u8,
};

pub const keymap = [_]KeyMapEntry{
    .{ .cp = '1', .chip = 0x1 },
    .{ .cp = '2', .chip = 0x2 },
    .{ .cp = '3', .chip = 0x3 },
    .{ .cp = '4', .chip = 0xC },
    .{ .cp = 'q', .chip = 0x4 },
    .{ .cp = 'w', .chip = 0x5 },
    .{ .cp = 'e', .chip = 0x6 },
    .{ .cp = 'r', .chip = 0xD },
    .{ .cp = 'a', .chip = 0x7 },
    .{ .cp = 's', .chip = 0x8 },
    .{ .cp = 'd', .chip = 0x9 },
    .{ .cp = 'f', .chip = 0xE },
    .{ .cp = 'z', .chip = 0xA },
    .{ .cp = 'x', .chip = 0x0 },
    .{ .cp = 'c', .chip = 0xB },
    .{ .cp = 'v', .chip = 0xF },
};
