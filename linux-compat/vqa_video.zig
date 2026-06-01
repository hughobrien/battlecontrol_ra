const std = @import("std");

const mcga_width = 320;
const mcga_height = 200;
const vga_memory_start = 0xa0000;
const vga_memory_end = 0xc0000;

const CaptionList = extern struct {
    head: ?*anyopaque = null,
    tail: ?*anyopaque = null,
    tail_pred: ?*anyopaque = null,
};

const CaptionInfo = extern struct {
    next: ?*anyopaque = null,
    list: CaptionList = .{},
    font: ?*anyopaque = null,
    font_height: u8 = 0,
    font_width: u8 = 0,
    buffer: ?*anyopaque = null,
};

extern fn malloc(size: usize) callconv(.c) ?*anyopaque;
extern fn free(ptr: ?*anyopaque) callconv(.c) void;

export fn UnVQ_4x2(codebook: [*]const u8, pointers: [*]const u8, buffer: [*]u8, blocks_per_row: c_ulong, num_rows: c_ulong, buffer_width: c_ulong) callconv(.c) void {
    const destination = normalMemory(buffer) orelse return;
    unvq4x2(codebook, pointers, destination, @intCast(blocks_per_row), @intCast(num_rows), @intCast(buffer_width));
}

fn unvq4x2(codebook: [*]const u8, pointers: [*]const u8, buffer: [*]u8, blocks_per_row: usize, num_rows: usize, buffer_width: usize) void {
    const entries = blocks_per_row * num_rows;
    const row_offset = buffer_width * 2;

    var source_index: usize = 0;
    var row_start: usize = 0;
    var row: usize = 0;
    while (row != num_rows) : (row += 1) {
        var dest = row_start;
        var block: usize = 0;
        while (block != blocks_per_row) : (block += 1) {
            const low = pointers[source_index];
            const high = pointers[source_index + entries];
            source_index += 1;

            if (high == 0x0f) {
                @memset(buffer[dest..][0..4], low);
                @memset(buffer[dest + buffer_width ..][0..4], low);
            } else {
                const codebook_index = (@as(usize, high) << 8) | low;
                const codeword = codebook + (codebook_index * 8);
                @memcpy(buffer[dest..][0..4], codeword[0..4]);
                @memcpy(buffer[dest + buffer_width ..][0..4], codeword[4..8]);
            }

            dest += 4;
        }
        row_start += row_offset;
    }
}

export fn MCGA_Blit(buffer: [*]const u8, screen: ?[*]u8, image_width: c_long, image_height: c_long) callconv(.c) void {
    const destination = normalMemory(screen orelse return) orelse return;
    blitRows(buffer, destination, @intCast(image_width), @intCast(image_height), mcga_width);
}

fn blitRows(source: [*]const u8, destination: [*]u8, width: usize, height: usize, destination_pitch: usize) void {
    var row: usize = 0;
    while (row != height) : (row += 1) {
        @memcpy(destination[row * destination_pitch ..][0..width], source[row * width ..][0..width]);
    }
}

export fn MCGA_BufferCopy(buffer: [*]const u8, dummy: ?*anyopaque) callconv(.c) void {
    _ = buffer;
    _ = dummy;
}

fn normalMemory(pointer: [*]u8) ?[*]u8 {
    const address = @intFromPtr(pointer);
    if (address >= vga_memory_start and address < vga_memory_end) return null;
    return pointer;
}

export fn WaitNoVB(vbi_bit: c_short) callconv(.c) void {
    _ = vbi_bit;
}

export fn WaitVB(vbi_bit: c_short) callconv(.c) void {
    _ = vbi_bit;
}

export fn SetDAC(color: c_long, red: c_long, green: c_long, blue: c_long) callconv(.c) void {
    _ = color;
    _ = red;
    _ = green;
    _ = blue;
}

export fn _Z10TestVBIBitv() callconv(.c) c_long {
    return 0;
}

export fn _Z12OpenCaptionsPvS_(captions: ?*anyopaque, font: ?*anyopaque) callconv(.c) ?*CaptionInfo {
    const allocation = malloc(@sizeOf(CaptionInfo)) orelse return null;
    const caption_info: *CaptionInfo = @ptrCast(@alignCast(allocation));
    caption_info.* = .{
        .next = captions,
        .font = font,
        .buffer = captions,
    };
    return caption_info;
}

export fn _Z13CloseCaptionsP12_CaptionInfo(caption_info: ?*CaptionInfo) callconv(.c) void {
    free(caption_info);
}

export fn _Z10DoCaptionsP12_CaptionInfom(caption_info: ?*CaptionInfo, frame: c_ulong) callconv(.c) void {
    _ = caption_info;
    _ = frame;
}

test "UnVQ_4x2 expands multi-color and one-color blocks" {
    var codebook = [_]u8{0} ** (4 * 8);
    const first_codeword = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8 };
    const second_codeword = [_]u8{ 9, 10, 11, 12, 13, 14, 15, 16 };
    @memcpy(codebook[8..][0..8], &first_codeword);
    @memcpy(codebook[16..][0..8], &second_codeword);

    const pointers = [_]u8{
        1, 2,
        0, 0x0f,
    };
    var output = [_]u8{0xcc} ** (8 * 2);

    UnVQ_4x2(&codebook, &pointers, &output, 2, 1, 8);

    try std.testing.expectEqualSlices(u8, &.{ 1, 2, 3, 4, 2, 2, 2, 2 }, output[0..8]);
    try std.testing.expectEqualSlices(u8, &.{ 5, 6, 7, 8, 2, 2, 2, 2 }, output[8..16]);
}

test "UnVQ_4x2 advances by destination buffer width between block rows" {
    var codebook = [_]u8{0} ** (2 * 8);
    const codeword = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8 };
    @memcpy(codebook[8..][0..8], &codeword);

    const pointers = [_]u8{
        1, 1,
        0, 0,
    };
    var output = [_]u8{0xcc} ** (4 * 4);

    UnVQ_4x2(&codebook, &pointers, &output, 1, 2, 4);

    try std.testing.expectEqualSlices(u8, &.{ 1, 2, 3, 4 }, output[0..4]);
    try std.testing.expectEqualSlices(u8, &.{ 5, 6, 7, 8 }, output[4..8]);
    try std.testing.expectEqualSlices(u8, &.{ 1, 2, 3, 4 }, output[8..12]);
    try std.testing.expectEqualSlices(u8, &.{ 5, 6, 7, 8 }, output[12..16]);
}

test "UnVQ_4x2 ignores VGA physical memory addresses" {
    var codebook = [_]u8{0} ** 8;
    var pointers = [_]u8{0} ** 2;
    const vga_pointer: [*]u8 = @ptrFromInt(vga_memory_start);

    UnVQ_4x2(&codebook, &pointers, vga_pointer, 1, 1, 4);
}

test "MCGA_Blit copies rows into a 320 byte destination pitch" {
    const width = 4;
    const height = 3;
    var source = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 };
    var destination = [_]u8{0xcc} ** (mcga_width * height);

    MCGA_Blit(&source, &destination, width, height);

    try std.testing.expectEqualSlices(u8, source[0..4], destination[0..4]);
    try std.testing.expectEqualSlices(u8, source[4..8], destination[mcga_width..][0..4]);
    try std.testing.expectEqualSlices(u8, source[8..12], destination[mcga_width * 2 ..][0..4]);
    try std.testing.expectEqual(@as(u8, 0xcc), destination[4]);
}

test "MCGA_Blit ignores VGA physical memory addresses" {
    var source = [_]u8{ 1, 2, 3, 4 };
    const vga_pointer: [*]u8 = @ptrFromInt(vga_memory_start);

    MCGA_Blit(&source, vga_pointer, 4, 1);
}

test "caption handles expose the loaded buffer for VQA_Close" {
    var captions: u8 = 0x5a;
    var font: u8 = 0x33;

    const handle = _Z12OpenCaptionsPvS_(&captions, &font) orelse return error.TestUnexpectedResult;
    defer _Z13CloseCaptionsP12_CaptionInfo(handle);

    try std.testing.expectEqual(@intFromPtr(&captions), @intFromPtr(handle.buffer.?));
    try std.testing.expectEqual(@intFromPtr(&font), @intFromPtr(handle.font.?));
}

test "caption handle layout matches CAPTION.H on the active C target" {
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(CaptionList, "head"));
    try std.testing.expectEqual(@offsetOf(CaptionList, "head") + @sizeOf(?*anyopaque), @offsetOf(CaptionList, "tail"));
    try std.testing.expectEqual(@offsetOf(CaptionList, "tail") + @sizeOf(?*anyopaque), @offsetOf(CaptionList, "tail_pred"));
    try std.testing.expectEqual(@offsetOf(CaptionList, "tail_pred") + @sizeOf(?*anyopaque), @sizeOf(CaptionList));

    try std.testing.expectEqual(@as(usize, 0), @offsetOf(CaptionInfo, "next"));
    try std.testing.expectEqual(@offsetOf(CaptionInfo, "next") + @sizeOf(?*anyopaque), @offsetOf(CaptionInfo, "list"));
    try std.testing.expectEqual(@offsetOf(CaptionInfo, "list") + @sizeOf(CaptionList), @offsetOf(CaptionInfo, "font"));
    try std.testing.expectEqual(@offsetOf(CaptionInfo, "font") + @sizeOf(?*anyopaque), @offsetOf(CaptionInfo, "font_height"));
    try std.testing.expectEqual(@offsetOf(CaptionInfo, "font_height") + @sizeOf(u8), @offsetOf(CaptionInfo, "font_width"));
    try std.testing.expectEqual(
        std.mem.alignForward(usize, @offsetOf(CaptionInfo, "font_width") + @sizeOf(u8), @alignOf(?*anyopaque)),
        @offsetOf(CaptionInfo, "buffer"),
    );
    try std.testing.expectEqual(@offsetOf(CaptionInfo, "buffer") + @sizeOf(?*anyopaque), @sizeOf(CaptionInfo));
}

test "hardware port compatibility functions are non-mutating" {
    WaitNoVB(0);
    WaitVB(1);
    SetDAC(251, 255, 255, 255);
    try std.testing.expectEqual(@as(c_long, 0), _Z10TestVBIBitv());
}
