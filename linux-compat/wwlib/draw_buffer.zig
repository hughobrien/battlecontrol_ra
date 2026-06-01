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

const ClippedRect = struct {
    x0: c_int,
    y0: c_int,
    x1: c_int,
    y1: c_int,
    clipped_left: c_int,
    clipped_top: c_int,

    fn width(self: ClippedRect) c_int {
        return self.x1 - self.x0;
    }

    fn height(self: ClippedRect) c_int {
        return self.y1 - self.y0;
    }
};

fn clipHalfOpen(view: *const GraphicViewPort, x_pixel: c_int, y_pixel: c_int, pixel_width: c_int, pixel_height: c_int) ?ClippedRect {
    var x0 = x_pixel;
    var y0 = y_pixel;
    var x1 = x_pixel +% pixel_width;
    var y1 = y_pixel +% pixel_height;
    var clipped_left: c_int = 0;
    var clipped_top: c_int = 0;

    if (x0 < 0) {
        clipped_left = -x0;
        x0 = 0;
    }
    if (y0 < 0) {
        clipped_top = -y0;
        y0 = 0;
    }
    if (x1 > view.width) x1 = view.width;
    if (y1 > view.height) y1 = view.height;

    const clipped = ClippedRect{
        .x0 = x0,
        .y0 = y0,
        .x1 = x1,
        .y1 = y1,
        .clipped_left = clipped_left,
        .clipped_top = clipped_top,
    };
    if (clipped.width() <= 0 or clipped.height() <= 0) return null;
    return clipped;
}

fn copyForward(destination: [*]u8, source: [*]const u8, count: usize) void {
    var index: usize = 0;
    while (index != count) : (index += 1) {
        destination[index] = source[index];
    }
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

export fn Buffer_To_Buffer(this_object: *GraphicViewPort, x_pixel: c_int, y_pixel: c_int, pixel_width: c_int, pixel_height: c_int, dest_ptr: *anyopaque, buffer_size: c_long) callconv(.c) c_long {
    const clipped = clipHalfOpen(this_object, x_pixel, y_pixel, pixel_width, pixel_height) orelse return 0;
    const copy_width: usize = @intCast(clipped.width());
    const copy_height: usize = @intCast(clipped.height());

    if (@as(c_long, pixel_width) * @as(c_long, clipped.height()) > buffer_size) return 0;

    const source_stride = bytesPerRow(this_object);
    var source = basePointer(this_object) + @as(usize, @intCast(clipped.y0)) * source_stride + @as(usize, @intCast(clipped.x0));

    const dest: [*]u8 = @ptrCast(dest_ptr);
    const dest_stride: usize = @intCast(pixel_width);
    var destination = dest + @as(usize, @intCast(clipped.clipped_top)) * dest_stride + @as(usize, @intCast(clipped.clipped_left));

    var remaining_rows = copy_height;
    while (remaining_rows != 0) : (remaining_rows -= 1) {
        copyForward(destination, source, copy_width);
        source += source_stride;
        destination += dest_stride;
    }

    return clipped.width();
}

export fn Buffer_To_Page(x_pixel: c_int, y_pixel: c_int, pixel_width: c_int, pixel_height: c_int, src_ptr: ?*const anyopaque, dest: *GraphicViewPort) callconv(.c) c_long {
    const source_buffer: [*]const u8 = @ptrCast(src_ptr orelse return 0);
    const clipped = clipHalfOpen(dest, x_pixel, y_pixel, pixel_width, pixel_height) orelse return 0;
    const copy_width: usize = @intCast(clipped.width());
    const copy_height: usize = @intCast(clipped.height());

    const source_stride: usize = @intCast(pixel_width);
    var source = source_buffer + @as(usize, @intCast(clipped.clipped_top)) * source_stride + @as(usize, @intCast(clipped.clipped_left));

    const dest_stride = bytesPerRow(dest);
    var destination = basePointer(dest) + @as(usize, @intCast(clipped.y0)) * dest_stride + @as(usize, @intCast(clipped.x0));

    var remaining_rows = copy_height;
    while (remaining_rows != 0) : (remaining_rows -= 1) {
        copyForward(destination, source, copy_width);
        source += source_stride;
        destination += dest_stride;
    }

    return clipped.width();
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

test "Buffer_To_Buffer clips from the viewport into the matching destination offset" {
    var source = [_]u8{
        1, 2,  3,  4,  99, 99,
        5, 6,  7,  8,  99, 99,
        9, 10, 11, 12, 99, 99,
    };
    var destination = [_]u8{0} ** 12;
    var view = testView(&source, 4, 3, 2, 0);

    const copied_width = Buffer_To_Buffer(&view, -1, 1, 4, 3, &destination, destination.len);

    try std.testing.expectEqual(@as(c_long, 3), copied_width);
    try std.testing.expectEqualSlices(u8, &[_]u8{
        0, 5, 6,  7,
        0, 9, 10, 11,
        0, 0, 0,  0,
    }, &destination);
}

test "Buffer_To_Buffer preserves the old buffer size guard" {
    var source = [_]u8{
        1, 2, 3, 4,
        5, 6, 7, 8,
    };
    var destination = [_]u8{0} ** 8;
    var view = testView(&source, 4, 2, 0, 0);

    const copied_width = Buffer_To_Buffer(&view, 0, 0, 4, 2, &destination, 7);

    try std.testing.expectEqual(@as(c_long, 0), copied_width);
    try std.testing.expectEqualSlices(u8, &[_]u8{0} ** 8, &destination);
}

test "Buffer_To_Buffer clips right and bottom edges without shifting destination origin" {
    var source = [_]u8{
        1, 2,  3,  4,  99,
        5, 6,  7,  8,  99,
        9, 10, 11, 12, 99,
    };
    var destination = [_]u8{0} ** 12;
    var view = testView(&source, 4, 3, 1, 0);

    const copied_width = Buffer_To_Buffer(&view, 2, 1, 4, 3, &destination, destination.len);

    try std.testing.expectEqual(@as(c_long, 2), copied_width);
    try std.testing.expectEqualSlices(u8, &[_]u8{
        7,  8,  0, 0,
        11, 12, 0, 0,
        0,  0,  0, 0,
    }, &destination);
}

test "Buffer_To_Buffer clips the top edge into the matching destination row" {
    var source = [_]u8{
        1, 2,  3,  4,
        5, 6,  7,  8,
        9, 10, 11, 12,
    };
    var destination = [_]u8{0} ** 9;
    var view = testView(&source, 4, 3, 0, 0);

    const copied_width = Buffer_To_Buffer(&view, 1, -1, 3, 3, &destination, destination.len);

    try std.testing.expectEqual(@as(c_long, 3), copied_width);
    try std.testing.expectEqualSlices(u8, &[_]u8{
        0, 0, 0,
        2, 3, 4,
        6, 7, 8,
    }, &destination);
}

test "Buffer_To_Buffer uses the asm forward copy order for overlapping ranges" {
    var buffer = [_]u8{ 1, 2, 3, 4 };
    var view = testView(&buffer, 3, 1, 0, 0);

    const copied_width = Buffer_To_Buffer(&view, 0, 0, 3, 1, buffer[1..].ptr, buffer.len - 1);

    try std.testing.expectEqual(@as(c_long, 3), copied_width);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 1, 1, 1 }, &buffer);
}

test "Buffer_To_Buffer ignores rectangles with no visible area" {
    var source = [_]u8{ 1, 2, 3, 4 };
    var destination = [_]u8{ 9, 9, 9, 9 };
    var view = testView(&source, 2, 2, 0, 0);

    const copied_width = Buffer_To_Buffer(&view, 0, 2, 1, 1, &destination, destination.len);

    try std.testing.expectEqual(@as(c_long, 0), copied_width);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 9, 9, 9, 9 }, &destination);
}

test "Buffer_To_Buffer and Buffer_To_Page preserve a caller-style save and restore rectangle" {
    var screen = [_]u8{
        1,  2,  3,  4,  5,  0,
        6,  7,  8,  9,  10, 0,
        11, 12, 13, 14, 15, 0,
        16, 17, 18, 19, 20, 0,
    };
    const original = screen;
    var saved = [_]u8{0} ** 6;
    var view = testView(&screen, 5, 4, 1, 0);

    try std.testing.expectEqual(@as(c_long, 3), Buffer_To_Buffer(&view, 1, 1, 3, 2, &saved, saved.len));
    Buffer_Fill_Rect(&view, 1, 1, 3, 2, 99);
    try std.testing.expectEqual(@as(c_long, 3), Buffer_To_Page(1, 1, 3, 2, &saved, &view));

    try std.testing.expectEqualSlices(u8, &original, &screen);
}

test "Buffer_To_Buffer copies a whole viewport into a linear page buffer" {
    var screen = [_]u8{
        1, 2,  3,  4,  99,
        5, 6,  7,  8,  99,
        9, 10, 11, 12, 99,
    };
    var shadow = [_]u8{0} ** 12;
    var view = testView(&screen, 4, 3, 1, 0);

    const copied_width = Buffer_To_Buffer(&view, 0, 0, 4, 3, &shadow, shadow.len);

    try std.testing.expectEqual(@as(c_long, 4), copied_width);
    try std.testing.expectEqualSlices(u8, &[_]u8{
        1, 2,  3,  4,
        5, 6,  7,  8,
        9, 10, 11, 12,
    }, &shadow);
}

test "Buffer_To_Page clips from the source buffer into the viewport" {
    var destination = [_]u8{0} ** 18;
    var source = [_]u8{
        1, 2,  3,  4,
        5, 6,  7,  8,
        9, 10, 11, 12,
    };
    var view = testView(&destination, 4, 3, 2, 0);

    const copied_width = Buffer_To_Page(-1, -1, 4, 3, &source, &view);

    try std.testing.expectEqual(@as(c_long, 3), copied_width);
    try std.testing.expectEqualSlices(u8, &[_]u8{
        6,  7,  8,  0, 0, 0,
        10, 11, 12, 0, 0, 0,
        0,  0,  0,  0, 0, 0,
    }, &destination);
}

test "Buffer_To_Page clips right and bottom edges without shifting source origin" {
    var destination = [_]u8{0} ** 18;
    var source = [_]u8{
        1, 2,  3,  4,
        5, 6,  7,  8,
        9, 10, 11, 12,
    };
    var view = testView(&destination, 4, 3, 2, 0);

    const copied_width = Buffer_To_Page(2, 1, 4, 3, &source, &view);

    try std.testing.expectEqual(@as(c_long, 2), copied_width);
    try std.testing.expectEqualSlices(u8, &[_]u8{
        0, 0, 0, 0, 0, 0,
        0, 0, 1, 2, 0, 0,
        0, 0, 5, 6, 0, 0,
    }, &destination);
}

test "Buffer_To_Page copies small radar icon buffers into staging viewports" {
    var stage = [_]u8{0} ** 9;
    var icon = [_]u8{
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
    };
    var view = testView(&stage, 3, 3, 0, 0);

    const copied_width = Buffer_To_Page(0, 0, 3, 3, &icon, &view);

    try std.testing.expectEqual(@as(c_long, 3), copied_width);
    try std.testing.expectEqualSlices(u8, &icon, &stage);
}

test "Buffer_To_Page copies tile-sized source buffers into staging viewports" {
    var stage = [_]u8{0} ** (24 * 24);
    var tile = [_]u8{0} ** (24 * 24);
    for (&tile, 0..) |*pixel, index| {
        pixel.* = @intCast(index % 251);
    }
    var view = testView(&stage, 24, 24, 0, 0);

    const copied_width = Buffer_To_Page(0, 0, 24, 24, &tile, &view);

    try std.testing.expectEqual(@as(c_long, 24), copied_width);
    try std.testing.expectEqualSlices(u8, &tile, &stage);
}

test "Buffer_To_Page ignores null source buffers" {
    var destination = [_]u8{ 1, 2, 3, 4 };
    var view = testView(&destination, 2, 2, 0, 0);

    const copied_width = Buffer_To_Page(0, 0, 2, 2, null, &view);

    try std.testing.expectEqual(@as(c_long, 0), copied_width);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4 }, &destination);
}

test "Buffer_To_Page ignores rectangles with no visible area" {
    var destination = [_]u8{ 1, 2, 3, 4 };
    var source = [_]u8{ 9, 9, 9, 9 };
    var view = testView(&destination, 2, 2, 0, 0);

    const copied_width = Buffer_To_Page(2, 0, 1, 1, &source, &view);

    try std.testing.expectEqual(@as(c_long, 0), copied_width);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4 }, &destination);
}

test "Buffer_To_Page uses the asm forward copy order for overlapping ranges" {
    var buffer = [_]u8{ 1, 2, 3, 4 };
    var view = testView(&buffer, 4, 1, 0, 0);

    const copied_width = Buffer_To_Page(1, 0, 3, 1, &buffer, &view);

    try std.testing.expectEqual(@as(c_long, 3), copied_width);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 1, 1, 1 }, &buffer);
}
