const std = @import("std");

const icon_width = 24;
const icon_height = 24;

export fn Cache_Copy_Icon(icon_ptr: *const anyopaque, dest_ptr: *anyopaque, pitch: c_int) callconv(.c) void {
    var source: [*]const u8 = @ptrCast(icon_ptr);
    var destination: [*]u8 = @ptrCast(dest_ptr);

    var row: usize = 0;
    while (row != icon_height) : (row += 1) {
        @memcpy(destination[0..icon_width], source[0..icon_width]);
        source += icon_width;
        destination = addSigned(destination, pitch);
    }
}

fn addSigned(pointer: [*]u8, offset: c_int) [*]u8 {
    const address = @intFromPtr(pointer);
    if (offset >= 0) return @ptrFromInt(address + @as(usize, @intCast(offset)));
    return @ptrFromInt(address - @as(usize, @intCast(-offset)));
}

test "Cache_Copy_Icon copies a packed 24 by 24 icon" {
    var source: [icon_width * icon_height]u8 = undefined;
    for (&source, 0..) |*byte, index| {
        byte.* = @truncate(index);
    }

    var destination = [_]u8{0} ** (icon_width * icon_height);

    Cache_Copy_Icon(&source, &destination, icon_width);

    try std.testing.expectEqualSlices(u8, &source, &destination);
}

test "Cache_Copy_Icon preserves destination pitch padding" {
    const pitch = icon_width + 5;
    var source: [icon_width * icon_height]u8 = undefined;
    for (&source, 0..) |*byte, index| {
        byte.* = @truncate((index * 7) + 3);
    }

    var destination = [_]u8{0xcc} ** (pitch * icon_height);

    Cache_Copy_Icon(&source, &destination, pitch);

    var row: usize = 0;
    while (row != icon_height) : (row += 1) {
        const source_start = row * icon_width;
        const dest_start = row * pitch;
        try std.testing.expectEqualSlices(
            u8,
            source[source_start..][0..icon_width],
            destination[dest_start..][0..icon_width],
        );
        try std.testing.expectEqualSlices(
            u8,
            &[_]u8{0xcc} ** (pitch - icon_width),
            destination[dest_start + icon_width ..][0 .. pitch - icon_width],
        );
    }
}

test "Cache_Copy_Icon supports a negative destination pitch" {
    const pitch = -@as(c_int, icon_width);
    var source: [icon_width * icon_height]u8 = undefined;
    for (&source, 0..) |*byte, index| {
        byte.* = @truncate((index * 5) + 1);
    }

    var destination = [_]u8{0} ** (icon_width * icon_height);
    const last_row_start = icon_width * (icon_height - 1);

    Cache_Copy_Icon(&source, &destination[last_row_start], pitch);

    var row: usize = 0;
    while (row != icon_height) : (row += 1) {
        const source_start = row * icon_width;
        const dest_start = (icon_height - 1 - row) * icon_width;
        try std.testing.expectEqualSlices(
            u8,
            source[source_start..][0..icon_width],
            destination[dest_start..][0..icon_width],
        );
    }
}
