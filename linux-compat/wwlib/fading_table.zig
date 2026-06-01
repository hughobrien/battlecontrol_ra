const std = @import("std");

fn low32(value: c_long) u32 {
    return @truncate(@as(c_ulong, @bitCast(value)));
}

fn signedByte(value: u8) i8 {
    return @bitCast(value);
}

fn fadeChannel(original: u8, target: u8, fraction: u8) u8 {
    const delta = signedByte(original -% target);
    const scaled: i16 = @as(i16, delta) * @as(i16, signedByte(fraction >> 1));
    const shifted: u16 = @as(u16, @bitCast(scaled)) << 1;
    const adjustment: u8 = @truncate(shifted >> 8);
    return original -% adjustment;
}

fn comparisonValue(palette: [*]const u8, candidate: u8, ideal_red: u8, ideal_green: u8, ideal_blue: u8) u32 {
    const offset = @as(usize, candidate) * 3;
    const red = signedByte(palette[offset] -% ideal_red);
    const green = signedByte(palette[offset + 1] -% ideal_green);
    const blue = signedByte(palette[offset + 2] -% ideal_blue);

    return @as(u32, @intCast(@as(i16, red) * @as(i16, red))) +
        @as(u32, @intCast(@as(i16, green) * @as(i16, green))) +
        @as(u32, @intCast(@as(i16, blue) * @as(i16, blue)));
}

export fn Build_Fading_Table(palette_ptr: ?*const anyopaque, dest_ptr: ?*anyopaque, color: c_long, frac: c_long) callconv(.c) ?*anyopaque {
    if (palette_ptr == null or dest_ptr == null) return dest_ptr;

    const palette: [*]const u8 = @ptrCast(palette_ptr.?);
    const dest: [*]u8 = @ptrCast(dest_ptr.?);

    const color_index: usize = @intCast(low32(color));
    const target = palette[color_index * 3 ..][0..3];
    const fraction_bits = low32(frac);
    const fraction: u8 = if (fraction_bits < 0x100) @intCast(fraction_bits) else 0xff;

    dest[0] = 0;

    var source: u16 = 1;
    while (source <= 255) : (source += 1) {
        const source_index: usize = source;
        const source_color = palette[source_index * 3 ..][0..3];

        const ideal_red = fadeChannel(source_color[0], target[0], fraction);
        const ideal_green = fadeChannel(source_color[1], target[1], fraction);
        const ideal_blue = fadeChannel(source_color[2], target[2], fraction);

        var match_color: u8 = @truncate(color_index);
        var match_value: u32 = std.math.maxInt(u32);

        var candidate: u16 = 1;
        while (candidate <= 255) : (candidate += 1) {
            if (candidate == source) continue;

            const candidate_color: u8 = @intCast(candidate);
            const value = comparisonValue(palette, candidate_color, ideal_red, ideal_green, ideal_blue);
            if (value == 0) {
                match_color = candidate_color;
                break;
            }

            if (value <= match_value) {
                match_value = value;
                match_color = candidate_color;
            }
        }

        dest[source_index] = match_color;
    }

    return dest_ptr;
}

fn makeGrayPalette() [256 * 3]u8 {
    var palette: [256 * 3]u8 = undefined;
    for (0..256) |index| {
        palette[index * 3] = @intCast(index);
        palette[index * 3 + 1] = @intCast(index);
        palette[index * 3 + 2] = @intCast(index);
    }
    return palette;
}

test "Build_Fading_Table returns dest and preserves transparent black" {
    var palette = makeGrayPalette();
    var dest = [_]u8{0xaa} ** 256;

    const result = Build_Fading_Table(&palette, &dest, 0, 0);
    try std.testing.expectEqual(@intFromPtr(&dest), @intFromPtr(result.?));
    try std.testing.expectEqual(@as(u8, 0), dest[0]);
}

test "Build_Fading_Table skips self and keeps later equal-distance matches" {
    var palette = makeGrayPalette();
    var dest = [_]u8{0} ** 256;

    _ = Build_Fading_Table(&palette, &dest, 0, 0);

    try std.testing.expectEqual(@as(u8, 2), dest[1]);
    try std.testing.expectEqual(@as(u8, 11), dest[10]);
    try std.testing.expectEqual(@as(u8, 254), dest[255]);
}

test "Build_Fading_Table channel adjustment uses signed bytes" {
    try std.testing.expectEqual(@as(u8, 10), fadeChannel(250, 10, 255));
    try std.testing.expectEqual(@as(u8, 251), fadeChannel(10, 250, 255));
    try std.testing.expectEqual(@as(u8, 127), fadeChannel(0, 128, 255));
}

test "Build_Fading_Table treats negative fractions as clamped to 255" {
    var palette = makeGrayPalette();
    var clamped = [_]u8{0} ** 256;
    var negative = [_]u8{0} ** 256;

    _ = Build_Fading_Table(&palette, &clamped, 0, 255);
    _ = Build_Fading_Table(&palette, &negative, 0, -1);

    try std.testing.expectEqualSlices(u8, &clamped, &negative);
}

test "Build_Fading_Table returns dest without writing when inputs are null" {
    var dest = [_]u8{0xaa} ** 256;

    try std.testing.expectEqual(@as(?*anyopaque, null), Build_Fading_Table(null, null, 0, 0));
    const result = Build_Fading_Table(null, &dest, 0, 0);
    try std.testing.expectEqual(@intFromPtr(&dest), @intFromPtr(result.?));
    try std.testing.expectEqual(@as(u8, 0xaa), dest[0]);
}
