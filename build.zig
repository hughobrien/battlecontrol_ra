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
        "CODE/GLOBALS.CPP",
        "CODE/RGB.CPP",
        "CODE/HEAP.CPP",
        "CODE/VECTOR.CPP",
        "CODE/DYNAVEC.CPP",
        "WIN32LIB/DRAWBUFF/BUFFER.CPP",
        "WIN32LIB/DRAWBUFF/GBUFFER.CPP",
        "WIN32LIB/DRAWBUFF/BUFFGLBL.CPP",
        "WIN32LIB/MISC/DDRAW.CPP",
        "WIN32LIB/PALETTE/PALETTE.CPP",
        "WIN32LIB/TIMER/TIMER.CPP",
        "WIN32LIB/TIMER/TIMERDWN.CPP",
        "WIN32LIB/TIMER/TIMERINI.CPP",
        "CODE/KEYBOARD.CPP",
        "WIN32LIB/KEYBOARD/MOUSE.CPP",
        "CODE/INTERNET.CPP",
        "CODE/IPXADDR.CPP",
        "CODE/RAWFILE.CPP",
        "CODE/BFIOFILE.CPP",
        "CODE/BUFF.CPP",
        "CODE/CDFILE.CPP",
        "CODE/CCFILE.CPP",
        "CODE/CCDDE.CPP",
        "CODE/FIELD.CPP",
        "CODE/PACKET.CPP",
        "CODE/2KEYFRAM.CPP",
        "CODE/INTERPAL.CPP",
        "CODE/GADGET.CPP",
        "CODE/LINK.CPP",
        "CODE/CCPTR.CPP",
        "CODE/CONST.CPP",
        "CODE/COORD.CPP",
        "CODE/TARGET.CPP",
        "CODE/LAYER.CPP",
        "CODE/IOOBJ.CPP",
        "CODE/IOMAP.CPP",
        "CODE/MAP.CPP",
        "CODE/CELL.CPP",
        "CODE/FINDPATH.CPP",
        "CODE/DISPLAY.CPP",
        "CODE/CARGO.CPP",
        "CODE/COMBAT.CPP",
        "CODE/ANIM.CPP",
        "CODE/CCINI.CPP",
        "CODE/WARHEAD.CPP",
        "CODE/WEAPON.CPP",
        "CODE/AADATA.CPP",
        "CODE/AIRCRAFT.CPP",
        "CODE/ADATA.CPP",
        "CODE/BASE.CPP",
        "CODE/BBDATA.CPP",
        "CODE/BUILDING.CPP",
        "CODE/BDATA.CPP",
        "CODE/BULLET.CPP",
        "CODE/CDATA.CPP",
        "CODE/CRATE.CPP",
        "CODE/DOOR.CPP",
        "CODE/EVENT.CPP",
        "CODE/FACE.CPP",
        "CODE/FACING.CPP",
        "CODE/FACTORY.CPP",
        "CODE/FLY.CPP",
        "CODE/FUSE.CPP",
        "CODE/GSCREEN.CPP",
        "CODE/HELP.CPP",
        "CODE/HOUSE.CPP",
        "CODE/HSV.CPP",
        "CODE/HDATA.CPP",
        "CODE/INFANTRY.CPP",
        "CODE/IDATA.CPP",
        "CODE/LCWPIPE.CPP",
        "CODE/LCWSTRAW.CPP",
        "CODE/ODATA.CPP",
        "CODE/OVERLAY.CPP",
        "CODE/OPTIONS.CPP",
        "CODE/QUEUE.CPP",
        "CODE/REINF.CPP",
        "CODE/SDATA.CPP",
        "CODE/SHAPIPE.CPP",
        "CODE/SMUDGE.CPP",
        "CODE/SUPER.CPP",
        "CODE/TACTION.CPP",
        "CODE/TDATA.CPP",
        "CODE/TEVENT.CPP",
        "CODE/TEAM.CPP",
        "CODE/TEAMTYPE.CPP",
        "CODE/TEMPLATE.CPP",
        "CODE/TERRAIN.CPP",
        "CODE/THEME.CPP",
        "CODE/TRACKER.CPP",
        "CODE/TRIGGER.CPP",
        "CODE/TRIGTYPE.CPP",
        "CODE/UDATA.CPP",
        "CODE/UNIT.CPP",
        "CODE/UTRACKER.CPP",
        "CODE/VDATA.CPP",
        "CODE/VESSEL.CPP",
        "CODE/VORTEX.CPP",
        "CODE/ABSTRACT.CPP",
        "CODE/OBJECT.CPP",
        "CODE/MISSION.CPP",
        "CODE/RADIO.CPP",
        "CODE/TECHNO.CPP",
        "CODE/FOOT.CPP",
        "CODE/DRIVE.CPP",
        "WIN32LIB/DRAWBUFF/DRAWRECT.CPP",
        "WIN32LIB/MEM/ALLOC.CPP",
        "CODE/WINSTUB.CPP",
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
        "CODE/WOLSTRNG.CPP",
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

    const win32_shim_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/win32-shim/file_path.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const win32_shim = b.addObject(.{
        .name = "win32-file-path-shim",
        .root_module = win32_shim_module,
    });
    exe.root_module.addObject(win32_shim);

    const win32_misc_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/win32-shim/win32_misc.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const win32_misc = b.addObject(.{
        .name = "win32-misc-shim",
        .root_module = win32_misc_module,
    });
    exe.root_module.addObject(win32_misc);

    b.installArtifact(exe);
}
