const std = @import("std");
const builtin = @import("builtin");

const make_shape_compact: u16 = 0x0001;
const make_shape_nocomp: u16 = 0x0002;

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

const WWMouse = extern struct {
    mouse_cursor: ?[*]u8,
    mouse_x_hot: c_int,
    mouse_y_hot: c_int,
    cursor_width: c_int,
    cursor_height: c_int,
    mouse_buffer: ?[*]u8,
    mouse_buff_x: c_int,
    mouse_buff_y: c_int,
    max_width: c_int,
    max_height: c_int,
    mouse_cx_left: c_int,
    mouse_cy_upper: c_int,
    mouse_cx_right: c_int,
    mouse_cy_lower: c_int,
    mc_flags: u8,
    mc_count: u8,
    screen: ?*GraphicViewPort,
    prev_cursor: ?*anyopaque,
    mouse_update: c_int,
    state: c_int,
    erase_buffer: ?[*]u8,
    erase_buff_x: c_int,
    erase_buff_y: c_int,
    erase_buff_hot_x: c_int,
    erase_buff_hot_y: c_int,
    erase_flags: c_int,
    mouse_critical_section: CriticalSection,
    timer_handle: c_uint,
};

const CriticalSection = extern struct {
    debug_info: ?*anyopaque,
    lock_count: i32,
    recursion_count: i32,
    owning_thread: ?*anyopaque,
    lock_semaphore: ?*anyopaque,
    spin_count: usize,
};

export fn Mouse_Shadow_Buffer(this_object: *WWMouse, srcdst: *GraphicViewPort, buffer: *anyopaque, x: c_int, y: c_int, hotx: c_int, hoty: c_int, store: c_int) callconv(.c) void {
    const clipped = clipMouseRect(srcdst, this_object.cursor_width, this_object.cursor_height, x, y, hotx, hoty) orelse return;
    const row_width: usize = @intCast(clipped.width);
    const row_count: usize = @intCast(clipped.height);
    const screen_stride = bytesPerRow(srcdst);
    const cursor_stride: usize = @intCast(this_object.cursor_width);

    var screen = basePointer(srcdst) + @as(usize, @intCast(clipped.y)) * screen_stride + @as(usize, @intCast(clipped.x));
    var shadow: [*]u8 = @ptrCast(buffer);
    shadow += @as(usize, @intCast(clipped.source_y)) * cursor_stride + @as(usize, @intCast(clipped.source_x));

    var rows = row_count;
    while (rows != 0) : (rows -= 1) {
        if (store == 1) {
            @memcpy(shadow[0..row_width], screen[0..row_width]);
        } else {
            @memcpy(screen[0..row_width], shadow[0..row_width]);
        }
        screen += screen_stride;
        shadow += cursor_stride;
    }
}

export fn Draw_Mouse(this_object: *WWMouse, dest: *GraphicViewPort, mouse_x: c_int, mouse_y: c_int) callconv(.c) void {
    const source_cursor = this_object.mouse_cursor orelse return;
    const clipped = clipMouseRect(dest, this_object.cursor_width, this_object.cursor_height, mouse_x, mouse_y, this_object.mouse_x_hot, this_object.mouse_y_hot) orelse return;
    const row_width: usize = @intCast(clipped.width);
    const row_count: usize = @intCast(clipped.height);
    const screen_stride = bytesPerRow(dest);
    const cursor_stride: usize = @intCast(this_object.cursor_width);

    var screen = basePointer(dest) + @as(usize, @intCast(clipped.y)) * screen_stride + @as(usize, @intCast(clipped.x));
    var cursor = source_cursor + @as(usize, @intCast(clipped.source_y)) * cursor_stride + @as(usize, @intCast(clipped.source_x));

    var rows = row_count;
    while (rows != 0) : (rows -= 1) {
        var column: usize = 0;
        while (column != row_width) : (column += 1) {
            const pixel = cursor[column];
            if (pixel != 0) screen[column] = pixel;
        }
        screen += screen_stride;
        cursor += cursor_stride;
    }
}

export fn ASM_Set_Mouse_Cursor(this_object: *WWMouse, hotspot_x: c_int, hotspot_y: c_int, cursor: ?*anyopaque) callconv(.c) ?*anyopaque {
    const cursor_ptr = cursor orelse return swapPreviousCursor(this_object, null);
    var shape: [*]const u8 = @ptrCast(cursor_ptr);
    const source_shape_type = readU16(shape, 0);
    const shape_width: c_int = readU16(shape, 3);
    const shape_height: c_int = shape[5];

    if (shape_width > this_object.max_width or shape_height > this_object.max_height) {
        return swapPreviousCursor(this_object, cursor_ptr);
    }

    var shape_type = source_shape_type;
    if ((shape_type & make_shape_nocomp) == 0) {
        const staging_ptr = shapeStoragePointer() orelse return swapPreviousCursor(this_object, cursor_ptr);
        const staging: [*]u8 = @ptrCast(staging_ptr);
        const header_len = shapeHeaderLength(shape_type);

        writeU16(staging, 0, shape_type | make_shape_nocomp);
        @memcpy(staging[2..header_len], shape[2..header_len]);
        _ = lcwUncompress(shape + header_len, staging + header_len, readU16(shape, 8));

        shape = staging;
        shape_type |= make_shape_nocomp;
    }

    const destination = this_object.mouse_cursor orelse return swapPreviousCursor(this_object, cursor_ptr);
    expandShapeData(destination, shape, shape_type, @intCast(shape_width * shape_height));

    this_object.mouse_x_hot = hotspot_x;
    this_object.mouse_y_hot = hotspot_y;
    this_object.cursor_width = shape_width;
    this_object.cursor_height = shape_height;

    return swapPreviousCursor(this_object, cursor_ptr);
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

const ClippedMouseRect = struct {
    x: c_int,
    y: c_int,
    source_x: c_int,
    source_y: c_int,
    width: c_int,
    height: c_int,
};

fn clipMouseRect(view: *const GraphicViewPort, cursor_width: c_int, cursor_height: c_int, x: c_int, y: c_int, hotx: c_int, hoty: c_int) ?ClippedMouseRect {
    var x0 = x - hotx;
    var y0 = y - hoty;
    var x1 = x0 + cursor_width;
    var y1 = y0 + cursor_height;
    var source_x: c_int = 0;
    var source_y: c_int = 0;

    if (x1 <= 0 or y1 <= 0) return null;
    if (x0 >= view.width or y0 >= view.height) return null;

    if (x0 < 0) {
        source_x = -x0;
        x0 = 0;
    }
    if (y0 < 0) {
        source_y = -y0;
        y0 = 0;
    }
    if (x1 > view.width) x1 = view.width;
    if (y1 > view.height) y1 = view.height;

    const width = x1 - x0;
    const height = y1 - y0;
    if (width <= 0 or height <= 0) return null;

    return .{
        .x = x0,
        .y = y0,
        .source_x = source_x,
        .source_y = source_y,
        .width = width,
        .height = height,
    };
}

fn readU16(bytes: [*]const u8, offset: usize) u16 {
    return @as(u16, bytes[offset]) | (@as(u16, bytes[offset + 1]) << 8);
}

fn writeU16(bytes: [*]u8, offset: usize, value: u16) void {
    bytes[offset] = @truncate(value);
    bytes[offset + 1] = @truncate(value >> 8);
}

fn shapeHeaderLength(shape_type: u16) usize {
    return if ((shape_type & make_shape_compact) != 0) 26 else 10;
}

fn expandShapeData(destination: [*]u8, shape: [*]const u8, shape_type: u16, pixel_count: usize) void {
    const compact = (shape_type & make_shape_compact) != 0;
    const remap = shape + 10;
    var source = shape + shapeHeaderLength(shape_type);
    var written: usize = 0;

    while (written != pixel_count) {
        const value = source[0];
        source += 1;
        if (value == 0) {
            const count = @as(usize, source[0]);
            source += 1;
            @memset(destination[written..][0..count], 0);
            written += count;
        } else {
            destination[written] = if (compact) remap[value] else value;
            written += 1;
        }
    }
}

fn swapPreviousCursor(this_object: *WWMouse, cursor: ?*anyopaque) ?*anyopaque {
    const previous = this_object.prev_cursor;
    this_object.prev_cursor = cursor;
    return previous;
}

const ShapeStorage = if (builtin.is_test) struct {
    var _ShapeBuffer: ?*anyopaque = null;
} else struct {
    extern var _ShapeBuffer: ?*anyopaque;
};

fn shapeStoragePointer() ?*anyopaque {
    return ShapeStorage._ShapeBuffer;
}

fn lcwUncompress(source: [*]const u8, dest: [*]u8, length: usize) usize {
    if (!builtin.is_test) {
        return @intCast(LcwRuntime.LCW_Uncompress(source, dest, @intCast(length)));
    }
    return testLcwUncompress(source, dest, length);
}

const LcwRuntime = if (builtin.is_test) struct {} else struct {
    extern fn LCW_Uncompress(source: [*]const u8, dest: [*]u8, length: c_ulong) callconv(.c) c_ulong;
};

fn testLcwUncompress(source: [*]const u8, dest: [*]u8, length: usize) usize {
    var src = source;
    var out = dest;
    const start = dest;
    var written: usize = 0;

    while (written < length) {
        const max_count = length - written;
        const op_code = src[0];
        src += 1;

        if (op_code < 0x80) {
            var count = @min(@as(usize, op_code >> 4) + 3, max_count);
            const offset = @as(usize, src[0]) | (@as(usize, op_code & 0x0f) << 8);
            src += 1;
            var copy = out - offset;
            written += count;
            while (count != 0) : (count -= 1) {
                out[0] = copy[0];
                out += 1;
                copy += 1;
            }
        } else if ((op_code & 0x40) == 0) {
            if (op_code == 0x80) break;
            var count = @min(@as(usize, op_code & 0x3f), max_count);
            written += count;
            while (count != 0) : (count -= 1) {
                out[0] = src[0];
                out += 1;
                src += 1;
            }
        } else if (op_code == 0xfe) {
            const count = @min(@as(usize, src[0]) | (@as(usize, src[1]) << 8), max_count);
            const value = src[2];
            src += 3;
            @memset(out[0..count], value);
            out += count;
            written += count;
        } else if (op_code == 0xff) {
            var count = @min(@as(usize, src[0]) | (@as(usize, src[1]) << 8), max_count);
            const offset = @as(usize, src[2]) | (@as(usize, src[3]) << 8);
            src += 4;
            var copy = start + offset;
            written += count;
            while (count != 0) : (count -= 1) {
                out[0] = copy[0];
                out += 1;
                copy += 1;
            }
        } else {
            var count = @min(@as(usize, op_code & 0x3f) + 3, max_count);
            const offset = @as(usize, src[0]) | (@as(usize, src[1]) << 8);
            src += 2;
            var copy = start + offset;
            written += count;
            while (count != 0) : (count -= 1) {
                out[0] = copy[0];
                out += 1;
                copy += 1;
            }
        }
    }

    return @intFromPtr(out) - @intFromPtr(start);
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

fn testMouse(cursor: ?[*]u8, width: c_int, height: c_int) WWMouse {
    return .{
        .mouse_cursor = cursor,
        .mouse_x_hot = 0,
        .mouse_y_hot = 0,
        .cursor_width = width,
        .cursor_height = height,
        .mouse_buffer = null,
        .mouse_buff_x = -1,
        .mouse_buff_y = -1,
        .max_width = width,
        .max_height = height,
        .mouse_cx_left = 0,
        .mouse_cy_upper = 0,
        .mouse_cx_right = 0,
        .mouse_cy_lower = 0,
        .mc_flags = 0,
        .mc_count = 0,
        .screen = null,
        .prev_cursor = null,
        .mouse_update = 0,
        .state = 0,
        .erase_buffer = null,
        .erase_buff_x = -1,
        .erase_buff_y = -1,
        .erase_buff_hot_x = 0,
        .erase_buff_hot_y = 0,
        .erase_flags = 0,
        .mouse_critical_section = std.mem.zeroes(CriticalSection),
        .timer_handle = 0,
    };
}

fn putU16(bytes: []u8, offset: usize, value: u16) void {
    bytes[offset] = @truncate(value);
    bytes[offset + 1] = @truncate(value >> 8);
}

test "WWMouse layout matches the C++ object layout on the current target" {
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(WWMouse, "mouse_cursor"));
    try std.testing.expectEqual(@as(usize, 8), @offsetOf(WWMouse, "mouse_x_hot"));
    try std.testing.expectEqual(@as(usize, 16), @offsetOf(WWMouse, "cursor_width"));
    try std.testing.expectEqual(@as(usize, 24), @offsetOf(WWMouse, "mouse_buffer"));
    try std.testing.expectEqual(@as(usize, 64), @offsetOf(WWMouse, "mc_flags"));
    try std.testing.expectEqual(@as(usize, 72), @offsetOf(WWMouse, "screen"));
    try std.testing.expectEqual(@as(usize, 80), @offsetOf(WWMouse, "prev_cursor"));
    try std.testing.expectEqual(@as(usize, 128), @offsetOf(WWMouse, "mouse_critical_section"));
    try std.testing.expectEqual(@as(usize, 168), @offsetOf(WWMouse, "timer_handle"));
    try std.testing.expectEqual(@as(usize, 40), @sizeOf(CriticalSection));
    try std.testing.expectEqual(@as(usize, 176), @sizeOf(WWMouse));
}

test "Mouse_Shadow_Buffer stores the clipped screen rectangle into cursor buffer coordinates" {
    var screen = [_]u8{
        1, 2,  3,  4,  99,
        5, 6,  7,  8,  99,
        9, 10, 11, 12, 99,
    };
    var shadow = [_]u8{0xcc} ** 6;
    var view = testView(&screen, 4, 3, 1, 0);
    var mouse = testMouse(null, 3, 2);

    Mouse_Shadow_Buffer(&mouse, &view, &shadow, 0, 0, 1, 1, 1);

    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xcc, 0xcc, 0xcc, 0xcc, 1, 2 }, &shadow);
}

test "Mouse_Shadow_Buffer restores the clipped cursor buffer rectangle to the screen" {
    var screen = [_]u8{0} ** 15;
    var shadow = [_]u8{ 20, 21, 22, 23, 24, 25 };
    var view = testView(&screen, 4, 3, 1, 0);
    var mouse = testMouse(null, 3, 2);

    Mouse_Shadow_Buffer(&mouse, &view, &shadow, 0, 0, 1, 1, 0);

    try std.testing.expectEqualSlices(u8, &[_]u8{
        24, 25, 0, 0, 0,
        0,  0,  0, 0, 0,
        0,  0,  0, 0, 0,
    }, &screen);
}

test "Draw_Mouse clips to the viewport and treats zero cursor pixels as transparent" {
    var screen = [_]u8{
        1, 1, 1, 1, 99,
        2, 2, 2, 2, 99,
        3, 3, 3, 3, 99,
    };
    var cursor = [_]u8{
        0, 5, 6,
        7, 0, 8,
    };
    var view = testView(&screen, 4, 3, 1, 0);
    var mouse = testMouse(&cursor, 3, 2);
    mouse.mouse_x_hot = 1;
    mouse.mouse_y_hot = 1;

    Draw_Mouse(&mouse, &view, 0, 0);

    try std.testing.expectEqualSlices(u8, &[_]u8{
        1, 8, 1, 1, 99,
        2, 2, 2, 2, 99,
        3, 3, 3, 3, 99,
    }, &screen);
}

test "Draw_Mouse clips right and bottom edges without shifting the cursor source origin" {
    var screen = [_]u8{
        1, 1, 1, 1, 99,
        2, 2, 2, 2, 99,
        3, 3, 3, 3, 99,
    };
    var cursor = [_]u8{
        4, 5, 6,
        7, 8, 9,
    };
    var view = testView(&screen, 4, 3, 1, 0);
    var mouse = testMouse(&cursor, 3, 2);

    Draw_Mouse(&mouse, &view, 2, 2);

    try std.testing.expectEqualSlices(u8, &[_]u8{
        1, 1, 1, 1, 99,
        2, 2, 2, 2, 99,
        3, 3, 4, 5, 99,
    }, &screen);
}

test "ASM_Set_Mouse_Cursor expands uncompressed normal shape RLE into the cursor buffer" {
    var destination = [_]u8{0xaa} ** 8;
    var old_shape = [_]u8{0x44};
    var shape = [_]u8{0} ** 18;
    putU16(&shape, 0, 2);
    shape[2] = 2;
    putU16(&shape, 3, 4);
    shape[5] = 2;
    putU16(&shape, 6, shape.len);
    putU16(&shape, 8, 8);
    @memcpy(shape[10..], &[_]u8{ 5, 0, 2, 6, 7, 8, 9, 10 });

    var mouse = testMouse(&destination, 8, 8);
    mouse.prev_cursor = &old_shape;

    const previous = ASM_Set_Mouse_Cursor(&mouse, 2, 1, &shape);

    try std.testing.expectEqual(@intFromPtr(&old_shape), @intFromPtr(previous.?));
    try std.testing.expectEqual(@intFromPtr(&shape), @intFromPtr(mouse.prev_cursor.?));
    try std.testing.expectEqual(@as(c_int, 2), mouse.mouse_x_hot);
    try std.testing.expectEqual(@as(c_int, 1), mouse.mouse_y_hot);
    try std.testing.expectEqual(@as(c_int, 4), mouse.cursor_width);
    try std.testing.expectEqual(@as(c_int, 2), mouse.cursor_height);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 5, 0, 0, 6, 7, 8, 9, 10 }, &destination);
}

test "ASM_Set_Mouse_Cursor expands uncompressed compact shape pixels through its color table" {
    var destination = [_]u8{0xaa} ** 4;
    var old_shape = [_]u8{0x44};
    var shape = [_]u8{0} ** 33;
    putU16(&shape, 0, make_shape_nocomp | make_shape_compact);
    shape[2] = 1;
    putU16(&shape, 3, 4);
    shape[5] = 1;
    putU16(&shape, 6, shape.len);
    putU16(&shape, 8, 4);
    shape[11] = 0x31;
    shape[12] = 0x32;
    @memcpy(shape[26..], &[_]u8{ 1, 2, 0, 2, 0, 0, 0 });

    var mouse = testMouse(&destination, 8, 8);
    mouse.prev_cursor = &old_shape;

    const previous = ASM_Set_Mouse_Cursor(&mouse, 0, 0, &shape);

    try std.testing.expectEqual(@intFromPtr(&old_shape), @intFromPtr(previous.?));
    try std.testing.expectEqual(@intFromPtr(&shape), @intFromPtr(mouse.prev_cursor.?));
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x31, 0x32, 0, 0 }, &destination);
}

test "ASM_Set_Mouse_Cursor rejects oversized shapes but still swaps PrevCursor like the ASM" {
    var destination = [_]u8{0xaa} ** 4;
    var old_shape = [_]u8{0x44};
    var shape = [_]u8{0} ** 14;
    putU16(&shape, 0, 2);
    shape[2] = 1;
    putU16(&shape, 3, 5);
    shape[5] = 1;
    putU16(&shape, 6, shape.len);
    putU16(&shape, 8, 5);
    @memcpy(shape[10..], &[_]u8{ 1, 2, 3, 4 });

    var mouse = testMouse(&destination, 2, 2);
    mouse.prev_cursor = &old_shape;

    const previous = ASM_Set_Mouse_Cursor(&mouse, 0, 0, &shape);

    try std.testing.expectEqual(@intFromPtr(&old_shape), @intFromPtr(previous.?));
    try std.testing.expectEqual(@intFromPtr(&shape), @intFromPtr(mouse.prev_cursor.?));
    try std.testing.expectEqual(@as(c_int, 2), mouse.cursor_width);
    try std.testing.expectEqual(@as(c_int, 2), mouse.cursor_height);
    try std.testing.expectEqualSlices(u8, &[_]u8{0xaa} ** 4, &destination);
}

test "ASM_Set_Mouse_Cursor expands compressed shapes through the shared shape buffer" {
    var staging = [_]u8{0} ** 32;
    ShapeStorage._ShapeBuffer = &staging;

    var destination = [_]u8{0xaa} ** 4;
    var old_shape = [_]u8{0x44};
    var shape = [_]u8{0} ** 17;
    putU16(&shape, 0, 0);
    shape[2] = 1;
    putU16(&shape, 3, 4);
    shape[5] = 1;
    putU16(&shape, 6, shape.len);
    putU16(&shape, 8, 4);
    @memcpy(shape[10..], &[_]u8{ 0x84, 1, 2, 0, 2, 0x80, 0 });

    var mouse = testMouse(&destination, 8, 8);
    mouse.prev_cursor = &old_shape;

    const previous = ASM_Set_Mouse_Cursor(&mouse, 0, 0, &shape);

    try std.testing.expectEqual(@intFromPtr(&old_shape), @intFromPtr(previous.?));
    try std.testing.expectEqual(@intFromPtr(&shape), @intFromPtr(mouse.prev_cursor.?));
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 0, 0 }, &destination);
}

test "addressBits keeps GraphicViewPort offsets as raw pointer bits" {
    try std.testing.expectEqual(@as(usize, @intCast(std.math.maxInt(c_ulong))), addressBits(@bitCast(@as(c_ulong, std.math.maxInt(c_ulong)))));
}
