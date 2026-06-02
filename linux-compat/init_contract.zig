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
    try std.testing.expect(std.mem.indexOf(u8, source, "&& !getenv(\"RA_AUTOSTART\")") == null);
}

test "xvfb launcher passes explicit skip-intro flag" {
    const source = try readFile(std.testing.allocator, "linux-compat/launcher/ra_xvfb_launcher.py");
    defer std.testing.allocator.free(source);

    try std.testing.expect(std.mem.indexOf(u8, source, "\"--skip-intro\"") != null);
}
