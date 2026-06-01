const std = @import("std");

// The original Win32 unsigned long accumulator was 32-bit; keep the wrap width.
fn addCrc(crc: *u32, value: u32) void {
    const high_bit: u32 = if ((crc.* & 0x80000000) != 0) 1 else 0;
    crc.* = (crc.* << 1) +% value +% high_bit;
}

fn computeNameCRC(name: [*:0]u8) callconv(.c) c_ulong {
    var crc: u32 = 0;
    var index: usize = 0;
    while (name[index] != 0) : (index += 1) {
        addCrc(&crc, std.ascii.toUpper(name[index]));
    }
    return crc;
}

comptime {
    @export(&computeNameCRC, .{ .name = "_Z16Compute_Name_CRCPc", .linkage = .strong });
}

fn writeByte(dest: [*]u8, out_index: *usize, value: u8) void {
    dest[out_index.*] = value;
    out_index.* += 1;
}

fn writeWord(dest: [*]u8, out_index: *usize, value: usize) void {
    writeByte(dest, out_index, @truncate(value));
    writeByte(dest, out_index, @truncate(value >> 8));
}

fn literalByte(source: [*]const u8, dest: [*]u8, src_index: *usize, out_index: *usize, length_offset: *usize, in_length: *bool) void {
    if (!in_length.*) {
        length_offset.* = out_index.*;
        writeByte(dest, out_index, 0x80);
    }

    if (dest[length_offset.*] == 0xbf) {
        length_offset.* = out_index.*;
        writeByte(dest, out_index, 0x80);
    }

    dest[length_offset.*] +%= 1;
    writeByte(dest, out_index, source[src_index.*]);
    src_index.* += 1;
    in_length.* = true;
}

fn matchingRunLength(source: [*]const u8, source_index: usize, candidate_index: usize, data_size: usize) usize {
    var count: usize = 0;
    while (source_index + count < data_size and source[source_index + count] == source[candidate_index + count]) {
        count += 1;
    }
    return count;
}

fn repeatedByteRunLength(source: [*]const u8, source_index: usize, data_size: usize) usize {
    const value = source[source_index];
    var count: usize = 0;
    while (source_index + count < data_size and source[source_index + count] == value) {
        count += 1;
    }

    if (source_index + count == data_size and count != 0) count -= 1;
    return count;
}

export fn LCW_Comp(source_ptr: *const anyopaque, dest_ptr: *anyopaque, length: c_int) callconv(.c) c_int {
    if (length <= 0) return 0;

    const source: [*]const u8 = @ptrCast(source_ptr);
    const dest: [*]u8 = @ptrCast(dest_ptr);
    const data_size: usize = @intCast(length);

    var out_index: usize = 0;
    var src_index: usize = 0;
    var length_offset: usize = 0;
    var in_length = true;

    writeByte(dest, &out_index, 0x81);
    writeByte(dest, &out_index, source[src_index]);
    src_index += 1;

    while (src_index < data_size) {
        if (src_index + 64 < data_size and source[src_index] == source[src_index + 64]) {
            const run_count = repeatedByteRunLength(source, src_index, data_size);
            if (run_count >= 65) {
                writeByte(dest, &out_index, 0xfe);
                writeWord(dest, &out_index, run_count);
                writeByte(dest, &out_index, source[src_index]);
                src_index += run_count;
                in_length = false;
                continue;
            }
        }

        var best_count: usize = 1;
        var best_offset: usize = 0;
        var candidate: usize = 0;
        while (candidate < src_index) {
            if (source[candidate] != source[src_index]) {
                candidate += 1;
                continue;
            }

            if (src_index + best_count - 1 < data_size and source[candidate + best_count - 1] == source[src_index + best_count - 1]) {
                const count = matchingRunLength(source, src_index, candidate, data_size);
                if (count >= best_count) {
                    best_count = count;
                    best_offset = candidate;
                }
            }
            candidate += 1;
        }

        if (best_count <= 2) {
            literalByte(source, dest, &src_index, &out_index, &length_offset, &in_length);
            continue;
        }

        const distance = src_index - best_offset;
        if (best_count <= 10 and distance <= 0x0fff) {
            writeByte(dest, &out_index, @as(u8, @intCast(((best_count - 3) << 4) | (distance >> 8))));
            writeByte(dest, &out_index, @truncate(distance));
        } else if (best_count <= 64) {
            writeByte(dest, &out_index, @as(u8, @intCast((best_count - 3) | 0xc0)));
            writeWord(dest, &out_index, best_offset);
        } else {
            writeByte(dest, &out_index, 0xff);
            writeWord(dest, &out_index, best_count);
            writeWord(dest, &out_index, best_offset);
        }

        src_index += best_count;
        in_length = false;
    }

    writeByte(dest, &out_index, 0x80);
    return @intCast(out_index);
}

fn lcwUncomp(source: []const u8, dest: []u8) usize {
    var source_index: usize = 0;
    var dest_index: usize = 0;
    while (true) {
        const op_code = source[source_index];
        source_index += 1;

        if ((op_code & 0x80) == 0) {
            var count: usize = (op_code >> 4) + 3;
            var copy_index = dest_index - (@as(usize, source[source_index]) + ((@as(usize, op_code) & 0x0f) << 8));
            source_index += 1;
            while (count != 0) : (count -= 1) {
                dest[dest_index] = dest[copy_index];
                dest_index += 1;
                copy_index += 1;
            }
        } else if ((op_code & 0x40) == 0) {
            if (op_code == 0x80) return dest_index;
            var count: usize = op_code & 0x3f;
            while (count != 0) : (count -= 1) {
                dest[dest_index] = source[source_index];
                dest_index += 1;
                source_index += 1;
            }
        } else if (op_code == 0xfe) {
            var count = @as(usize, source[source_index]) | (@as(usize, source[source_index + 1]) << 8);
            const value = source[source_index + 2];
            source_index += 3;
            while (count != 0) : (count -= 1) {
                dest[dest_index] = value;
                dest_index += 1;
            }
        } else if (op_code == 0xff) {
            var count = @as(usize, source[source_index]) | (@as(usize, source[source_index + 1]) << 8);
            var copy_index = @as(usize, source[source_index + 2]) | (@as(usize, source[source_index + 3]) << 8);
            source_index += 4;
            while (count != 0) : (count -= 1) {
                dest[dest_index] = dest[copy_index];
                dest_index += 1;
                copy_index += 1;
            }
        } else {
            var count: usize = (op_code & 0x3f) + 3;
            var copy_index = @as(usize, source[source_index]) | (@as(usize, source[source_index + 1]) << 8);
            source_index += 2;
            while (count != 0) : (count -= 1) {
                dest[dest_index] = dest[copy_index];
                dest_index += 1;
                copy_index += 1;
            }
        }
    }
}

fn expectLcwRoundTrip(input: []const u8, compressed: []u8, decompressed: []u8) !usize {
    const compressed_len = LCW_Comp(input.ptr, compressed.ptr, @intCast(input.len));
    const decompressed_len = lcwUncomp(compressed[0..@intCast(compressed_len)], decompressed);

    try std.testing.expectEqual(input.len, decompressed_len);
    try std.testing.expectEqualSlices(u8, input, decompressed[0..decompressed_len]);
    return @intCast(compressed_len);
}

test "Compute_Name_CRC uppercases names before adding CRC values" {
    var empty = [_:0]u8{};
    var lower = [_:0]u8{ 'r', 'e', 'd' };
    var upper = [_:0]u8{ 'R', 'E', 'D' };
    var mixed = [_:0]u8{ 'R', 'e', 'd', ' ', 'A', 'l', 'e', 'r', 't' };
    var max_session_name = [_:0]u8{ 'r', 'e', 'd', 'a', 'l', 'e', 'r', 't', '1', '2', '3' };
    var wrap = [_:0]u8{'Z'} ** 40;

    try std.testing.expectEqual(@as(c_ulong, 0), computeNameCRC(&empty));
    try std.testing.expectEqual(computeNameCRC(&upper), computeNameCRC(&lower));
    try std.testing.expectEqual(@as(c_ulong, 534), computeNameCRC(&lower));
    try std.testing.expectEqual(@as(c_ulong, 37_372), computeNameCRC(&mixed));
    try std.testing.expectEqual(@as(c_ulong, 154_427), computeNameCRC(&max_session_name));
    try std.testing.expectEqual(@as(c_ulong, 22_822), computeNameCRC(&wrap));
}

test "LCW_Comp emits a literal packet for short unique data" {
    const input = "ABC";
    var compressed = [_]u8{0} ** 16;

    const compressed_len = LCW_Comp(input.ptr, &compressed, input.len);

    try std.testing.expectEqual(@as(c_int, 5), compressed_len);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x83, 'A', 'B', 'C', 0x80 }, compressed[0..@intCast(compressed_len)]);
}

test "LCW_Comp round-trips repeated patterns through LCW decompression" {
    const input = "ABCABCABCABCXYZXYZXYZABCABC";
    var compressed = [_]u8{0} ** 128;
    var decompressed = [_]u8{0} ** input.len;

    _ = try expectLcwRoundTrip(input, &compressed, &decompressed);
}

test "LCW_Comp handles LCWPipe full block and flush block inputs" {
    const block_size = 1024 * 8;
    const safety_margin = block_size / 128 + 1;
    var full_block: [block_size]u8 = undefined;
    for (&full_block, 0..) |*value, index| {
        value.* = @intCast((index * 17 + index / 7) & 0xff);
    }

    var full_compressed = [_]u8{0xcc} ** (block_size + safety_margin + 16);
    var full_decompressed = [_]u8{0} ** block_size;
    const full_compressed_len = try expectLcwRoundTrip(&full_block, full_compressed[0 .. block_size + safety_margin], &full_decompressed);
    try std.testing.expect(full_compressed_len <= block_size + safety_margin);
    try std.testing.expectEqualSlices(u8, &([_]u8{0xcc} ** 16), full_compressed[block_size + safety_margin ..]);

    const flush_len = 173;
    var flush_block: [flush_len]u8 = undefined;
    for (&flush_block, 0..) |*value, index| {
        value.* = @intCast((index * 5 + 3) & 0xff);
    }

    var flush_compressed = [_]u8{0xdd} ** (block_size + safety_margin + 16);
    var flush_decompressed = [_]u8{0} ** flush_len;
    const flush_compressed_len = try expectLcwRoundTrip(&flush_block, flush_compressed[0 .. block_size + safety_margin], &flush_decompressed);
    try std.testing.expect(flush_compressed_len <= block_size + safety_margin);
    try std.testing.expectEqualSlices(u8, &([_]u8{0xdd} ** 16), flush_compressed[block_size + safety_margin ..]);
}

test "LCW_Comp supports LCWStraw writing after a block header" {
    const block_size = 1024 * 8;
    const safety_margin = block_size / 128 + 1;
    const header_len = 4;
    const input = "MAPDATA-MAPDATA-MAPDATA-END";
    var output = [_]u8{0xaa} ** (block_size + safety_margin + 16);
    var decompressed = [_]u8{0} ** input.len;

    const compressed_len = LCW_Comp(input.ptr, output[header_len .. block_size + safety_margin].ptr, input.len);
    try std.testing.expect(@as(usize, @intCast(compressed_len)) <= block_size + safety_margin - header_len);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xaa, 0xaa, 0xaa, 0xaa }, output[0..header_len]);
    try std.testing.expectEqualSlices(u8, &([_]u8{0xaa} ** 16), output[block_size + safety_margin ..]);

    const decompressed_len = lcwUncomp(output[header_len .. header_len + @as(usize, @intCast(compressed_len))], &decompressed);
    try std.testing.expectEqual(input.len, decompressed_len);
    try std.testing.expectEqualSlices(u8, input, &decompressed);
}

test "LCW_Comp preserves the old long repeated byte run shape" {
    const input = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
    var compressed = [_]u8{0} ** 128;
    var decompressed = [_]u8{0} ** input.len;

    const compressed_len = LCW_Comp(input.ptr, &compressed, input.len);
    const output = compressed[0..@intCast(compressed_len)];

    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x81, 'A', 0xfe, 0x44, 0x00, 'A', 0x81, 'A', 0x80 }, output);
    const decompressed_len = lcwUncomp(output, &decompressed);
    try std.testing.expectEqual(input.len, decompressed_len);
    try std.testing.expectEqualSlices(u8, input, &decompressed);
}
