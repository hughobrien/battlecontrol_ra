const std = @import("std");

fn readFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    return try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        path,
        allocator,
        .limited(128 * 1024),
    );
}

test "CompHeaderType keeps the 8-byte CPS disk layout on 64-bit hosts" {
    const paths = [_][]const u8{
        "WIN32LIB/IFF/IFF.H",
        "WIN32LIB/INCLUDE/IFF.H",
        "VQ/INCLUDE/WWLIB32/IFF.H",
    };

    for (paths) |path| {
        const source = try readFile(std.testing.allocator, path);
        defer std.testing.allocator.free(source);

        try std.testing.expect(std.mem.indexOf(u8, source, "#pragma pack(push, 1)") != null);
        try std.testing.expect(std.mem.indexOf(u8, source, "uint32_t\tSize;") != null);
        try std.testing.expect(std.mem.indexOf(u8, source, "uint16_t\tSkip;") != null);
        try std.testing.expect(std.mem.indexOf(u8, source, "long\tSize;") == null);
        try std.testing.expect(std.mem.indexOf(u8, source, "LONG\tSize;") == null);
    }
}
