const std = @import("std");
const zhip8 = @import("zhip8");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    const allocator = std.heap.page_allocator;

    const file_data = zhip8.read_file(allocator) catch |err| {
        try stdout.print("Error reading file: {}\n", .{err});
        return err;
    };
    defer allocator.free(file_data);

    try stdout.print("File contents:\n{s}\n", .{file_data});
    try stdout.flush();
}
