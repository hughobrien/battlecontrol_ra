const std = @import("std");

fn readVectorCpp(allocator: std.mem.Allocator) ![]u8 {
    return try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "CODE/VECTOR.CPP",
        allocator,
        .limited(1024 * 1024),
    );
}

test "BooleanVectorClass allocates storage for dword bit helpers" {
    const source = try readVectorCpp(std.testing.allocator);
    defer std.testing.allocator.free(source);

    try std.testing.expect(std.mem.indexOf(u8, source, "Boolean_Vector_Storage_Size") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "BitArray.Resize(Boolean_Vector_Storage_Size(size)") != null);
}
