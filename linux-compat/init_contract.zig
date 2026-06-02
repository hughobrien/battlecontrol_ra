const std = @import("std");

fn readFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    return try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        path,
        allocator,
        .limited(512 * 1024),
    );
}

test "intro skipping is controlled by explicit command-line flag" {
    const source = try readFile(std.testing.allocator, "CODE/INIT.CPP");
    defer std.testing.allocator.free(source);

    try std.testing.expect(std.mem.indexOf(u8, source, "stricmp(argv[index], \"--skip-intro\") == 0") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "RA_AUTOSTART") == null);
}

test "default scenario start still requests briefing playback" {
    const init = try readFile(std.testing.allocator, "CODE/INIT.CPP");
    defer std.testing.allocator.free(init);
    const function_header = try readFile(std.testing.allocator, "CODE/FUNCTION.H");
    defer std.testing.allocator.free(function_header);

    try std.testing.expect(std.mem.indexOf(u8, function_header, "bool Start_Scenario(char *root, bool briefing=true);") != null);
    try std.testing.expect(std.mem.indexOf(u8, init, "Start_Scenario(Scen.ScenarioName, true)") != null);
    try std.testing.expect(std.mem.indexOf(u8, init, "Start_Scenario(Scen.ScenarioName, false)") == null);
}

test "xvfb launcher passes explicit skip-intro flag" {
    const source = try readFile(std.testing.allocator, "linux-compat/launcher/ra_xvfb_launcher.py");
    defer std.testing.allocator.free(source);

    try std.testing.expect(std.mem.indexOf(u8, source, "\"--skip-intro\"") != null);
}

test "Linux smoke controls are explicit command-line flags" {
    const startup = try readFile(std.testing.allocator, "CODE/STARTUP.CPP");
    defer std.testing.allocator.free(startup);

    try std.testing.expect(std.mem.indexOf(u8, startup, "\"--capture-bmp\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, startup, "\"--capture-ready\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, startup, "\"--inject-keys\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, startup, "\"--inject-key-delay-ms\"") != null);

    const ddraw = try readFile(std.testing.allocator, "linux-compat/ddraw-mini/sdl_backend.zig");
    defer std.testing.allocator.free(ddraw);
    try std.testing.expect(std.mem.indexOf(u8, ddraw, "RA_CAPTURE_BMP_FILE") == null);
    try std.testing.expect(std.mem.indexOf(u8, ddraw, "RA_CAPTURE_READY_FILE") == null);

    const win32 = try readFile(std.testing.allocator, "linux-compat/win32-shim/win32_misc.zig");
    defer std.testing.allocator.free(win32);
    try std.testing.expect(std.mem.indexOf(u8, win32, "BATTLECONTROL_KEY_SEQUENCE") == null);
    try std.testing.expect(std.mem.indexOf(u8, win32, "BATTLECONTROL_KEY_DELAY_MS") == null);
}
