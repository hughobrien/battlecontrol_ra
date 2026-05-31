const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const cnc_ddraw_source = b.option([]const u8, "cnc-ddraw-source", "Path to the cnc-ddraw source tree") orelse "";

    const exe_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    exe_module.addCMacro("WIN32", "1");
    exe_module.addCMacro("_WIN32", "1");

    if (cnc_ddraw_source.len != 0) {
        exe_module.addIncludePath(b.path("linux-compat/win32-shim"));
        exe_module.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ cnc_ddraw_source, "inc" }) });
    }
    exe_module.addIncludePath(b.path("CODE"));
    exe_module.addIncludePath(b.path("WIN32LIB/INCLUDE"));
    exe_module.addIncludePath(b.path("VQ/INCLUDE"));
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
