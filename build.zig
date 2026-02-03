const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Core library
    const zhip8 = b.addModule("zhip8", .{
        .root_source_file = b.path("core/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Executable root module (Zig 0.15 requires this)
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("core/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zhip8", .module = zhip8 },
        },
    });

    const exe = b.addExecutable(.{
        .name = "zhip8",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    // wasm library
    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
        .abi = .none,
    });
    const wasm_mod = b.createModule(.{
        .root_source_file = b.path("core/root.zig"),
        .target = wasm_target,
        .optimize = optimize,
    });
    const wasm = b.addExecutable(.{
        .name = "zhip8",
        .root_module = wasm_mod,
    });
    wasm.entry = .disabled;
    b.installArtifact(wasm);
    const wasm_step = b.step("wasm", "Build the wasm binary");
    wasm_step.dependOn(&wasm.step);
    wasm_step.dependOn(b.getInstallStep());

    // Run
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    b.step("run", "Run the app").dependOn(&run_cmd.step);

    // Tests
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = zhip8 })).step);
    test_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = exe_mod })).step);
}
