const std = @import("std");

const GraphicViewPort = extern struct {
    offset: c_long,
    width: c_int,
    height: c_int,
    x_add: c_int,
    x_pos: c_int,
    y_pos: c_int,
    pitch: c_long,
    graphic_buffer: ?*anyopaque,
    is_direct_draw: c_int,
    lock_count: c_int,
};

fn truncateI16(value: c_int) i32 {
    return @as(i32, @as(i16, @bitCast(@as(u16, @truncate(@as(c_uint, @bitCast(value)))))));
}

fn addressBits(value: c_long) usize {
    return @intCast(@as(c_ulong, @bitCast(value)));
}

fn basePointer(view: *const GraphicViewPort) [*]u8 {
    return @ptrFromInt(addressBits(view.offset));
}

fn bytesPerRow(view: *const GraphicViewPort) usize {
    return @intCast(@as(c_long, view.width) + @as(c_long, view.x_add) + view.pitch);
}

export fn Buffer_Fill_Rect(this_object: *GraphicViewPort, x1_pixel: c_int, y1_pixel: c_int, x2_pixel: c_int, y2_pixel: c_int, color: u8) callconv(.c) void {
    var x1 = truncateI16(x1_pixel);
    var y1 = truncateI16(y1_pixel);
    var x2 = truncateI16(x2_pixel);
    var y2 = truncateI16(y2_pixel);

    if (x1 >= x2) std.mem.swap(i32, &x1, &x2);
    if (y1 >= y2) std.mem.swap(i32, &y1, &y2);

    var fill_width = x2 - x1 + 1;
    var fill_height = y2 - y1 + 1;

    if (x1 >= this_object.width) return;
    if (x1 < 0) {
        fill_width += x1;
        x1 = 0;
    }

    if (y1 >= this_object.height) return;
    if (y1 < 0) {
        fill_height += y1;
        y1 = 0;
    }

    const max_width = this_object.width - x1;
    if (fill_width > max_width) fill_width = max_width;

    const max_height = this_object.height - y1;
    if (fill_height > max_height) fill_height = max_height;

    if (fill_width <= 0 or fill_height <= 0) return;
    if (fill_width > this_object.width or fill_height > this_object.height) return;

    const stride = bytesPerRow(this_object);
    var row = basePointer(this_object) + @as(usize, @intCast(y1)) * stride + @as(usize, @intCast(x1));
    const row_width: usize = @intCast(fill_width);

    var remaining_rows: usize = @intCast(fill_height);
    while (remaining_rows != 0) : (remaining_rows -= 1) {
        @memset(row[0..row_width], color);
        row += stride;
    }
}

export fn Buffer_Remap(this_object: *GraphicViewPort, x0_pixel: c_int, y0_pixel: c_int, region_width: c_int, region_height: c_int, remap_ptr: ?*const anyopaque) callconv(.c) void {
    const remap: [*]const u8 = @ptrCast(remap_ptr orelse return);

    var x0 = x0_pixel;
    var y0 = y0_pixel;
    var x1 = x0 +% region_width;
    var y1 = y0 +% region_height;

    if (x0 < 0) x0 = 0;
    if (y0 < 0) y0 = 0;
    if (x1 > this_object.width) x1 = this_object.width;
    if (y1 > this_object.height) y1 = this_object.height;

    const remap_width = x1 -% x0;
    const remap_height = y1 -% y0;
    if (remap_width <= 0 or remap_height <= 0) return;

    const stride = bytesPerRow(this_object);
    var row = basePointer(this_object) + @as(usize, @intCast(y0)) * stride + @as(usize, @intCast(x0));
    const row_width: usize = @intCast(remap_width);

    var remaining_rows: usize = @intCast(remap_height);
    while (remaining_rows != 0) : (remaining_rows -= 1) {
        for (row[0..row_width]) |*pixel| {
            pixel.* = remap[pixel.*];
        }
        row += stride;
    }
}

test "GraphicViewPort layout matches the C++ object layout on the current target" {
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(GraphicViewPort, "offset"));
    try std.testing.expectEqual(@as(usize, @sizeOf(c_long)), @offsetOf(GraphicViewPort, "width"));
    try std.testing.expectEqual(@as(usize, @sizeOf(c_long) + 4), @offsetOf(GraphicViewPort, "height"));
    try std.testing.expectEqual(@as(usize, @sizeOf(c_long) + 8), @offsetOf(GraphicViewPort, "x_add"));
    try std.testing.expectEqual(@as(usize, @sizeOf(c_long) + 12), @offsetOf(GraphicViewPort, "x_pos"));
    try std.testing.expectEqual(@as(usize, @sizeOf(c_long) + 16), @offsetOf(GraphicViewPort, "y_pos"));
    try std.testing.expectEqual(@as(usize, @sizeOf(c_long) + 24), @offsetOf(GraphicViewPort, "pitch"));
    try std.testing.expectEqual(@as(usize, @sizeOf(c_long) + 32), @offsetOf(GraphicViewPort, "graphic_buffer"));
    try std.testing.expectEqual(@as(usize, @sizeOf(c_long) + 40), @offsetOf(GraphicViewPort, "is_direct_draw"));
    try std.testing.expectEqual(@as(usize, @sizeOf(c_long) + 44), @offsetOf(GraphicViewPort, "lock_count"));
    try std.testing.expectEqual(@as(usize, @sizeOf(c_long) + 48), @sizeOf(GraphicViewPort));
}

fn testView(buffer: []u8, width: c_int, height: c_int, x_add: c_int, pitch: c_long) GraphicViewPort {
    return .{
        .offset = @bitCast(@as(c_ulong, @intCast(@intFromPtr(buffer.ptr)))),
        .width = width,
        .height = height,
        .x_add = x_add,
        .x_pos = 0,
        .y_pos = 0,
        .pitch = pitch,
        .graphic_buffer = null,
        .is_direct_draw = 0,
        .lock_count = 0,
    };
}

test "GraphicViewPort offset is treated as raw address bits" {
    try std.testing.expectEqual(@as(usize, @intCast(std.math.maxInt(c_ulong))), addressBits(@bitCast(@as(c_ulong, std.math.maxInt(c_ulong)))));
}

test "Buffer_Fill_Rect fills inclusive rectangles and swaps endpoints" {
    var buffer = [_]u8{0} ** 25;
    var view = testView(&buffer, 5, 5, 0, 0);

    Buffer_Fill_Rect(&view, 3, 3, 1, 1, 7);

    try std.testing.expectEqualSlices(u8, &[_]u8{
        0, 0, 0, 0, 0,
        0, 7, 7, 7, 0,
        0, 7, 7, 7, 0,
        0, 7, 7, 7, 0,
        0, 0, 0, 0, 0,
    }, &buffer);
}

test "Buffer_Fill_Rect clips to the viewport and honors row pitch" {
    var buffer = [_]u8{0} ** 18;
    var view = testView(&buffer, 4, 3, 2, 0);

    Buffer_Fill_Rect(&view, -2, 1, 2, 4, 9);

    try std.testing.expectEqualSlices(u8, &[_]u8{
        0, 0, 0, 0, 0, 0,
        9, 9, 9, 0, 0, 0,
        9, 9, 9, 0, 0, 0,
    }, &buffer);
}

test "Buffer_Remap clips and remaps only the selected rectangle" {
    var buffer = [_]u8{
        0, 1, 2, 3, 0,
        4, 5, 6, 7, 0,
        8, 9, 1, 2, 0,
    };
    var remap = [_]u8{0} ** 256;
    for (0..remap.len) |index| remap[index] = @intCast(255 - index);
    var view = testView(&buffer, 4, 3, 1, 0);

    Buffer_Remap(&view, 1, -1, 5, 3, &remap);

    try std.testing.expectEqualSlices(u8, &[_]u8{
        0, 254, 253, 252, 0,
        4, 250, 249, 248, 0,
        8, 9,   1,   2,   0,
    }, &buffer);
}

test "Buffer_Remap ignores null remap tables" {
    var buffer = [_]u8{ 1, 2, 3, 4 };
    var view = testView(&buffer, 2, 2, 0, 0);

    Buffer_Remap(&view, 0, 0, 2, 2, null);

    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4 }, &buffer);
}
