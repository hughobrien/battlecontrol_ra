export var _ShapeBuffer: ?*anyopaque = null;
export var _ShapeBufferSize: c_long = 0;

comptime {
    @export(&_ShapeBuffer, .{ .name = "ShapeBuffer", .linkage = .strong });
    @export(&_ShapeBufferSize, .{ .name = "ShapeBufferSize", .linkage = .strong });
}

export fn Set_Shape_Buffer(buffer: ?*const anyopaque, size: c_int) callconv(.c) void {
    const mutable_buffer: ?*anyopaque = if (buffer) |ptr| @constCast(ptr) else null;

    _ShapeBufferSize = size;
    _ShapeBuffer = mutable_buffer;
}

extern var ShapeBuffer: ?*anyopaque;
extern var ShapeBufferSize: c_long;

test "Set_Shape_Buffer updates underscored and plain shape globals" {
    var bytes = [_]u8{ 1, 2, 3, 4 };

    Set_Shape_Buffer(&bytes, 4);

    try std.testing.expectEqual(@as(c_long, 4), _ShapeBufferSize);
    try std.testing.expectEqual(@as(c_long, 4), ShapeBufferSize);
    try std.testing.expectEqual(@intFromPtr(&bytes), @intFromPtr(_ShapeBuffer.?));
    try std.testing.expectEqual(@intFromPtr(&bytes), @intFromPtr(ShapeBuffer.?));

    Set_Shape_Buffer(null, 0);

    try std.testing.expectEqual(@as(c_long, 0), _ShapeBufferSize);
    try std.testing.expectEqual(@as(c_long, 0), ShapeBufferSize);
    try std.testing.expectEqual(null, _ShapeBuffer);
    try std.testing.expectEqual(null, ShapeBuffer);
}

test "shape globals support the existing staging buffer calling pattern" {
    var bytes = [_]u8{0} ** 8;

    Set_Shape_Buffer(&bytes, bytes.len);

    const shape_bytes: [*]u8 = @ptrCast(_ShapeBuffer.?);
    @memset(shape_bytes[0..@intCast(_ShapeBufferSize)], 0xaa);

    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa }, &bytes);
}

test "plain and underscored shape symbols are writable aliases" {
    var first = [_]u8{ 1, 2 };
    var second = [_]u8{ 3, 4 };

    Set_Shape_Buffer(&first, first.len);
    ShapeBuffer = &second;
    ShapeBufferSize = second.len;

    try std.testing.expectEqual(@intFromPtr(&second), @intFromPtr(_ShapeBuffer.?));
    try std.testing.expectEqual(@as(c_long, second.len), _ShapeBufferSize);
}

const std = @import("std");
