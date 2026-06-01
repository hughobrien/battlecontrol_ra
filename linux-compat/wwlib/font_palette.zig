const std = @import("std");

pub export var ColorXlat: [241]u8 = initColorXlat();

fn initColorXlat() [241]u8 {
    var table = [_]u8{0} ** 241;
    for (0..16) |index| {
        table[index] = @intCast(index);
        table[index * 16] = @intCast(index);
    }
    return table;
}

export fn Set_Font_Palette_Range(palette: [*]const u8, start_idx: c_int, end_idx: c_int) callconv(.c) void {
    const start: usize = @intCast(start_idx & 0x0f);
    const end: usize = @intCast(end_idx & 0x0f);
    if (end < start) return;

    var index = start;
    while (index <= end) : (index += 1) {
        const color = palette[index - start];
        ColorXlat[index] = color;
        ColorXlat[index * 16] = color;
    }
}

test "ColorXlat matches text print assembly initializer" {
    try std.testing.expectEqual(@as(usize, 241), ColorXlat.len);
    for (0..ColorXlat.len) |index| {
        const expected: u8 = if (index < 16)
            @intCast(index)
        else if ((index & 0x0f) == 0)
            @intCast(index / 16)
        else
            0;
        try std.testing.expectEqual(expected, ColorXlat[index]);
    }
}

test "Set_Font_Palette_Range masks bounds and updates low and high nibble slots" {
    var palette = [_]u8{ 10, 11, 12, 13 };

    Set_Font_Palette_Range(&palette, 17, 19);
    try std.testing.expectEqual(@as(u8, 10), ColorXlat[1]);
    try std.testing.expectEqual(@as(u8, 10), ColorXlat[16]);
    try std.testing.expectEqual(@as(u8, 11), ColorXlat[2]);
    try std.testing.expectEqual(@as(u8, 11), ColorXlat[32]);
    try std.testing.expectEqual(@as(u8, 12), ColorXlat[3]);
    try std.testing.expectEqual(@as(u8, 12), ColorXlat[48]);

    Set_Font_Palette_Range(&palette, 3, 1);
    try std.testing.expectEqual(@as(u8, 10), ColorXlat[1]);

    Set_Font_Palette_Range(&palette, -1, -1);
    try std.testing.expectEqual(@as(u8, 10), ColorXlat[15]);
    try std.testing.expectEqual(@as(u8, 10), ColorXlat[240]);
}
