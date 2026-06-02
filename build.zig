const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const sdl3_include = b.option([]const u8, "sdl3-include", "Path to SDL3 include directory");
    const sdl3_lib = b.option([]const u8, "sdl3-lib", "Path to SDL3 library directory");
    const exe_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    exe_module.addCMacro("WIN32", "1");
    exe_module.addCMacro("_WIN32", "1");
    exe_module.addCMacro("ENGLISH", "1");

    exe_module.addIncludePath(b.path("linux-compat/win32-shim"));
    exe_module.addIncludePath(b.path("linux-compat"));
    exe_module.addIncludePath(b.path("CODE"));
    exe_module.addIncludePath(b.path("WIN32LIB/INCLUDE"));
    exe_module.addIncludePath(b.path("VQ/INCLUDE"));
    if (sdl3_lib) |path| {
        exe_module.addLibraryPath(.{ .cwd_relative = path });
        exe_module.addRPath(.{ .cwd_relative = path });
    }
    exe_module.linkSystemLibrary("SDL3", .{});
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
        "WIN32LIB/DRAWBUFF/ICONCACH.CPP",
        "WIN32LIB/FONT/FONT.CPP",
        "WIN32LIB/FONT/LOADFONT.CPP",
        "WIN32LIB/FONT/SET_FONT.CPP",
        "WIN32LIB/IFF/IFF.CPP",
        "WIN32LIB/IFF/LOAD.CPP",
        "WIN32LIB/IFF/WRITEPCX.CPP",
        "WIN32LIB/MISC/DDRAW.CPP",
        "WIN32LIB/MISC/DELAY.CPP",
        "WIN32LIB/PALETTE/PALETTE.CPP",
        "WIN32LIB/PLAYCD/GETCD.CPP",
        "WIN32LIB/SHAPE/GETSHAPE.CPP",
        "WIN32LIB/TILE/ICONSET.CPP",
        "WIN32LIB/WW_WIN/WINDOWS.CPP",
        "WIN32LIB/WSA/WSA.CPP",
        "WIN32LIB/DIPTHONG/DIPTHONG.CPP",
        "WIN32LIB/DIPTHONG/_DIPTABL.CPP",
        "WIN32LIB/TIMER/TIMER.CPP",
        "WIN32LIB/TIMER/TIMERDWN.CPP",
        "WIN32LIB/TIMER/TIMERINI.CPP",
        "VQ/VQA32/CONFIG.CPP",
        "VQ/VQA32/DSTREAM.CPP",
        "VQ/VQA32/LOADER.CPP",
        "VQ/VQA32/DRAWER.CPP",
        "VQ/VQA32/MONODISP.CPP",
        "VQ/VQA32/AUDIO.CPP",
        "VQ/VQM32/PROFILE.CPP",
        "VQ/VQA32/TASK.CPP",
        "CODE/KEYBOARD.CPP",
        "WIN32LIB/KEYBOARD/MOUSE.CPP",
        "CODE/INTERNET.CPP",
        "CODE/STATS.CPP",
        "CODE/INIT.CPP",
        "CODE/MENUS.CPP",
        "CODE/INTRO.CPP",
        "CODE/NETDLG.CPP",
        "CODE/CHEKLIST.CPP",
        "CODE/COLRLIST.CPP",
        "CODE/DROP.CPP",
        "CODE/SENDFILE.CPP",
        "CODE/IPXMGR.CPP",
        "CODE/IPX.CPP",
        "CODE/IPXCONN.CPP",
        "CODE/IPXGCONN.CPP",
        "CODE/COMBUF.CPP",
        "CODE/CONNECT.CPP",
        "CODE/WOL_GSUP.CPP",
        "CODE/IPXADDR.CPP",
        "CODE/IPX95.CPP",
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
        "CODE/EDIT.CPP",
        "CODE/CHECKBOX.CPP",
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
        "CODE/CARRY.CPP",
        "CODE/COMBAT.CPP",
        "CODE/ANIM.CPP",
        "CODE/AUDIO.CPP",
        "CODE/CCINI.CPP",
        "CODE/CONQUER.CPP",
        "CODE/CONTROL.CPP",
        "CODE/CREDITS.CPP",
        "CODE/DIALOG.CPP",
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
        "CODE/EXPAND.CPP",
        "CODE/FACE.CPP",
        "CODE/FACING.CPP",
        "CODE/FACTORY.CPP",
        "CODE/FLY.CPP",
        "CODE/FUSE.CPP",
        "CODE/FLASHER.CPP",
        "CODE/GAUGE.CPP",
        "CODE/GOPTIONS.CPP",
        "CODE/GAMEDLG.CPP",
        "CODE/GSCREEN.CPP",
        "CODE/HELP.CPP",
        "CODE/HOUSE.CPP",
        "CODE/HSV.CPP",
        "CODE/HDATA.CPP",
        "CODE/INFANTRY.CPP",
        "CODE/IDATA.CPP",
        "CODE/JSHELL.CPP",
        "CODE/LCW.CPP",
        "CODE/LCWPIPE.CPP",
        "CODE/LCWSTRAW.CPP",
        "CODE/LIST.CPP",
        "CODE/LZO1X_C.CPP",
        "CODE/LZO1X_D.CPP",
        "CODE/LZOPIPE.CPP",
        "CODE/LZOSTRAW.CPP",
        "CODE/LOGIC.CPP",
        "CODE/MOUSE.CPP",
        "CODE/MPLAYER.CPP",
        "CODE/MPGSET.CPP",
        "CODE/MSGBOX.CPP",
        "CODE/MSGLIST.CPP",
        "CODE/TXTLABEL.CPP",
        "CODE/LOADDLG.CPP",
        "CODE/ODATA.CPP",
        "CODE/OVERLAY.CPP",
        "CODE/OPTIONS.CPP",
        "CODE/POWER.CPP",
        "CODE/QUEUE.CPP",
        "CODE/RADAR.CPP",
        "CODE/RAMFILE.CPP",
        "CODE/RECT.CPP",
        "CODE/REINF.CPP",
        "CODE/RULES.CPP",
        "CODE/ROTBMP.CPP",
        "CODE/SCENARIO.CPP",
        "CODE/SCROLL.CPP",
        "CODE/SCORE.CPP",
        "CODE/SAVELOAD.CPP",
        "CODE/SDATA.CPP",
        "CODE/SESSION.CPP",
        "CODE/SHAPEBTN.CPP",
        "CODE/SIDEBAR.CPP",
        "CODE/SLIDER.CPP",
        "CODE/SHAPIPE.CPP",
        "CODE/SMUDGE.CPP",
        "CODE/SOUNDDLG.CPP",
        "CODE/SPECIAL.CPP",
        "CODE/SPRITE.CPP",
        "CODE/STATBTN.CPP",
        "CODE/SUPER.CPP",
        "CODE/TAB.CPP",
        "CODE/TACTION.CPP",
        "CODE/TDATA.CPP",
        "CODE/TEVENT.CPP",
        "CODE/TEAM.CPP",
        "CODE/TEAMTYPE.CPP",
        "CODE/TEMPLATE.CPP",
        "CODE/TERRAIN.CPP",
        "CODE/THEME.CPP",
        "CODE/TEXTBTN.CPP",
        "CODE/TOGGLE.CPP",
        "CODE/TRACKER.CPP",
        "CODE/TRIGGER.CPP",
        "CODE/TRIGTYPE.CPP",
        "CODE/UDATA.CPP",
        "CODE/UNIT.CPP",
        "CODE/UTRACKER.CPP",
        "CODE/VDATA.CPP",
        "CODE/VESSEL.CPP",
        "CODE/VERSION.CPP",
        "CODE/VISUDLG.CPP",
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
        "CODE/EGOS.CPP",
        "CODE/INI.CPP",
        "CODE/MAPSEL.CPP",
        "CODE/MIXFILE.CPP",
        "CODE/MONOC.CPP",
        "CODE/STRAW.CPP",
        "CODE/PIPE.CPP",
        "CODE/XSTRAW.CPP",
        "CODE/XPIPE.CPP",
        "CODE/B64STRAW.CPP",
        "CODE/B64PIPE.CPP",
        "CODE/BASE64.CPP",
        "CODE/BLOWPIPE.CPP",
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

    const serial_disabled_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/serial_disabled.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    const serial_disabled = b.addObject(.{
        .name = "serial-disabled-shim",
        .root_module = serial_disabled_module,
    });
    exe.root_module.addObject(serial_disabled);

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

    const ddraw_mini_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/ddraw-mini/ddraw.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const ddraw_mini = b.addObject(.{
        .name = "ddraw-mini",
        .root_module = ddraw_mini_module,
    });
    exe.root_module.addObject(ddraw_mini);

    const ddraw_sdl_backend_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/ddraw-mini/sdl_backend.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    if (sdl3_include) |path| {
        ddraw_sdl_backend_module.addIncludePath(.{ .cwd_relative = path });
    }
    const ddraw_sdl_backend = b.addObject(.{
        .name = "ddraw-sdl-backend",
        .root_module = ddraw_sdl_backend_module,
    });
    exe.root_module.addObject(ddraw_sdl_backend);

    const ddraw_sdl_backend_test_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/ddraw-mini/sdl_backend.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    if (sdl3_include) |path| {
        ddraw_sdl_backend_test_module.addIncludePath(.{ .cwd_relative = path });
    }
    const ddraw_sdl_backend_tests = b.addTest(.{
        .root_module = ddraw_sdl_backend_test_module,
    });
    if (sdl3_lib) |path| {
        ddraw_sdl_backend_tests.root_module.addLibraryPath(.{ .cwd_relative = path });
        ddraw_sdl_backend_tests.root_module.addRPath(.{ .cwd_relative = path });
    }
    ddraw_sdl_backend_tests.root_module.linkSystemLibrary("SDL3", .{});
    const run_ddraw_sdl_backend_tests = b.addRunArtifact(ddraw_sdl_backend_tests);
    const test_step = b.step("test", "Run Nix-backed Zig tests");
    test_step.dependOn(&run_ddraw_sdl_backend_tests.step);

    const win32_misc_test_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/win32-shim/win32_misc.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const win32_misc_tests = b.addTest(.{
        .root_module = win32_misc_test_module,
    });
    win32_misc_tests.root_module.addObject(ddraw_sdl_backend);
    if (sdl3_lib) |path| {
        win32_misc_tests.root_module.addLibraryPath(.{ .cwd_relative = path });
        win32_misc_tests.root_module.addRPath(.{ .cwd_relative = path });
    }
    win32_misc_tests.root_module.linkSystemLibrary("SDL3", .{});
    const run_win32_misc_tests = b.addRunArtifact(win32_misc_tests);
    test_step.dependOn(&run_win32_misc_tests.step);

    const timer_contract_test_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/timer_contract.zig"),
        .target = target,
        .optimize = optimize,
    });
    const timer_contract_tests = b.addTest(.{
        .root_module = timer_contract_test_module,
    });
    const run_timer_contract_tests = b.addRunArtifact(timer_contract_tests);
    test_step.dependOn(&run_timer_contract_tests.step);

    const win32_shim_contract_test_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/win32_shim_contract.zig"),
        .target = target,
        .optimize = optimize,
    });
    const win32_shim_contract_tests = b.addTest(.{
        .root_module = win32_shim_contract_test_module,
    });
    const run_win32_shim_contract_tests = b.addRunArtifact(win32_shim_contract_tests);
    test_step.dependOn(&run_win32_shim_contract_tests.step);

    const init_contract_test_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/init_contract.zig"),
        .target = target,
        .optimize = optimize,
    });
    const init_contract_tests = b.addTest(.{
        .root_module = init_contract_test_module,
    });
    const run_init_contract_tests = b.addRunArtifact(init_contract_tests);
    test_step.dependOn(&run_init_contract_tests.step);

    const random_contract_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    random_contract_module.addIncludePath(b.path("CODE"));
    random_contract_module.addCSourceFile(.{
        .file = b.path("linux-compat/random_contract.cpp"),
        .flags = cxx_flags,
    });
    random_contract_module.addCSourceFile(.{
        .file = b.path("CODE/RANDOM.CPP"),
        .flags = cxx_flags,
    });
    const random_contract = b.addExecutable(.{
        .name = "random-contract",
        .root_module = random_contract_module,
    });
    const run_random_contract = b.addRunArtifact(random_contract);
    test_step.dependOn(&run_random_contract.step);

    const win32_mpeg_movie_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/win32-shim/mpeg_movie.zig"),
        .target = target,
        .optimize = optimize,
    });
    const win32_mpeg_movie = b.addObject(.{
        .name = "win32-mpeg-movie-shim",
        .root_module = win32_mpeg_movie_module,
    });
    exe.root_module.addObject(win32_mpeg_movie);

    const win32_tcpip_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/win32-shim/tcpip.zig"),
        .target = target,
        .optimize = optimize,
    });
    const win32_tcpip = b.addObject(.{
        .name = "win32-tcpip-shim",
        .root_module = win32_tcpip_module,
    });
    exe.root_module.addObject(win32_tcpip);

    const vqa_video_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/vqa_video.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const vqa_video = b.addObject(.{
        .name = "vqa-video-shim",
        .root_module = vqa_video_module,
    });
    exe.root_module.addObject(vqa_video);

    const wwlib_clip_rect_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/wwlib/clip_rect.zig"),
        .target = target,
        .optimize = optimize,
    });
    const wwlib_clip_rect = b.addObject(.{
        .name = "wwlib-clip-rect",
        .root_module = wwlib_clip_rect_module,
    });
    exe.root_module.addObject(wwlib_clip_rect);

    const wwlib_font_palette_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/wwlib/font_palette.zig"),
        .target = target,
        .optimize = optimize,
    });
    const wwlib_font_palette = b.addObject(.{
        .name = "wwlib-font-palette",
        .root_module = wwlib_font_palette_module,
    });
    exe.root_module.addObject(wwlib_font_palette);

    const wwlib_fading_table_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/wwlib/fading_table.zig"),
        .target = target,
        .optimize = optimize,
    });
    const wwlib_fading_table = b.addObject(.{
        .name = "wwlib-fading-table",
        .root_module = wwlib_fading_table_module,
    });
    exe.root_module.addObject(wwlib_fading_table);

    const wwlib_draw_buffer_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/wwlib/draw_buffer.zig"),
        .target = target,
        .optimize = optimize,
    });
    const wwlib_draw_buffer = b.addObject(.{
        .name = "wwlib-draw-buffer",
        .root_module = wwlib_draw_buffer_module,
    });
    exe.root_module.addObject(wwlib_draw_buffer);

    const wwlib_shape_buffer_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/wwlib/shape_buffer.zig"),
        .target = target,
        .optimize = optimize,
    });
    const wwlib_shape_buffer = b.addObject(.{
        .name = "wwlib-shape-buffer",
        .root_module = wwlib_shape_buffer_module,
    });
    exe.root_module.addObject(wwlib_shape_buffer);

    const wwlib_icon_cache_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/wwlib/icon_cache.zig"),
        .target = target,
        .optimize = optimize,
    });
    const wwlib_icon_cache = b.addObject(.{
        .name = "wwlib-icon-cache",
        .root_module = wwlib_icon_cache_module,
    });
    exe.root_module.addObject(wwlib_icon_cache);

    const wwlib_audio_state_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/wwlib/audio_state.zig"),
        .target = target,
        .optimize = optimize,
    });
    const wwlib_audio_state = b.addObject(.{
        .name = "wwlib-audio-state",
        .root_module = wwlib_audio_state_module,
    });
    exe.root_module.addObject(wwlib_audio_state);

    const wwlib_mouse_asm_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/wwlib/mouse_asm.zig"),
        .target = target,
        .optimize = optimize,
    });
    const wwlib_mouse_asm = b.addObject(.{
        .name = "wwlib-mouse-asm",
        .root_module = wwlib_mouse_asm_module,
    });
    exe.root_module.addObject(wwlib_mouse_asm);

    const wwlib_profile_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/wwlib/profile.zig"),
        .target = target,
        .optimize = optimize,
    });
    const wwlib_profile = b.addObject(.{
        .name = "wwlib-profile",
        .root_module = wwlib_profile_module,
    });
    exe.root_module.addObject(wwlib_profile);

    const game_algorithms_module = b.createModule(.{
        .root_source_file = b.path("linux-compat/game_algorithms.zig"),
        .target = target,
        .optimize = optimize,
    });
    const game_algorithms = b.addObject(.{
        .name = "game-algorithms",
        .root_module = game_algorithms_module,
    });
    exe.root_module.addObject(game_algorithms);

    b.installArtifact(exe);
}
