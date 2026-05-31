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
    exe_module.addCMacro("ENGLISH", "1");

    if (cnc_ddraw_source.len != 0) {
        exe_module.addIncludePath(b.path("linux-compat/win32-shim"));
        exe_module.addIncludePath(b.path("linux-compat"));
        exe_module.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ cnc_ddraw_source, "inc" }) });
    }
    exe_module.addIncludePath(b.path("CODE"));
    exe_module.addIncludePath(b.path("WIN32LIB/INCLUDE"));
    exe_module.addIncludePath(b.path("VQ/INCLUDE"));
    const cxx_flags = &.{
        "-std=c++17",
    };
    const sources = [_][]const u8{
        "CODE/STARTUP.CPP",
        "CODE/INTERNET.CPP",
        "CODE/RAWFILE.CPP",
        "CODE/BFIOFILE.CPP",
        "CODE/BUFF.CPP",
        "CODE/CDFILE.CPP",
        "CODE/CCFILE.CPP",
        "CODE/CCDDE.CPP",
        "CODE/DDE.CPP",
        "CODE/INI.CPP",
        "CODE/MIXFILE.CPP",
        "CODE/STRAW.CPP",
        "CODE/PIPE.CPP",
        "CODE/XSTRAW.CPP",
        "CODE/XPIPE.CPP",
        "CODE/B64STRAW.CPP",
        "CODE/B64PIPE.CPP",
        "CODE/BASE64.CPP",
        "CODE/PK.CPP",
        "CODE/PKSTRAW.CPP",
        "CODE/INT.CPP",
        "CODE/BLOWFISH.CPP",
        "CODE/BLWSTRAW.CPP",
        "CODE/SHASTRAW.CPP",
        "CODE/SHA.CPP",
        "CODE/RANDOM.CPP",
        "CODE/RNDSTRAW.CPP",
        "CODE/CRC.CPP",
        "CODE/FIXED.CPP",
        "CODE/MP.CPP",
        "CODE/PROFILE.CPP",
        "CODE/READLINE.CPP",
    };
    for (sources) |source| {
        exe_module.addCSourceFile(.{
            .file = b.path(source),
            .flags = cxx_flags,
        });
    }

    const exe = b.addExecutable(.{
        .name = "ra",
        .root_module = exe_module,
    });

    b.installArtifact(exe);
}
