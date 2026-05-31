const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });

    exe_module.addIncludePath(b.path("CODE"));
    exe_module.addIncludePath(b.path("WIN32LIB/INCLUDE"));
    exe_module.addCSourceFile(.{
        .file = b.path("CODE/STARTUP.CPP"),
        .flags = &.{
            "-std=c++17",
        },
    });

    const exe = b.addExecutable(.{
        .name = "ra",
        .root_module = exe_module,
    });

    b.installArtifact(exe);
}
