const std = @import("std");

fn readWin32Misc(allocator: std.mem.Allocator) ![]u8 {
    return try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "linux-compat/win32-shim/win32_misc.zig",
        allocator,
        .limited(256 * 1024),
    );
}

test "Win32 shim avoids busy-wait locking loops" {
    const source = try readWin32Misc(std.testing.allocator);
    defer std.testing.allocator.free(source);

    try std.testing.expect(std.mem.indexOf(u8, source, "tryLock") == null);
    try std.testing.expect(std.mem.indexOf(u8, source, "std.Thread.yield") == null);
}
