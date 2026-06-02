const std = @import("std");

pub const PaletteEntry = extern struct {
    peRed: u8,
    peGreen: u8,
    peBlue: u8,
    peFlags: u8,
};

pub const Backend = struct {
    width: u32 = 0,
    height: u32 = 0,

    pub fn initialize(self: *Backend, width: u32, height: u32) void {
        self.width = width;
        self.height = height;
    }

    pub fn shutdown(self: *Backend) void {
        self.* = .{};
    }

    pub fn presentIndexedSurface(
        self: *Backend,
        indexed_pixels: []const u8,
        pitch: usize,
        width: usize,
        height: usize,
        palette: []const PaletteEntry,
        argb_pixels: []u32,
    ) void {
        _ = self;
        expandIndexedRectToArgb(indexed_pixels, pitch, width, height, palette, argb_pixels);
    }
};

pub fn expandIndexedToArgb(indexed_pixels: []const u8, pitch: usize, palette: []const PaletteEntry, argb_pixels: []u32) void {
    expandIndexedRectToArgb(indexed_pixels, pitch, @min(pitch, argb_pixels.len), 1, palette, argb_pixels);
}

pub fn expandIndexedRectToArgb(
    indexed_pixels: []const u8,
    pitch: usize,
    width: usize,
    height: usize,
    palette: []const PaletteEntry,
    argb_pixels: []u32,
) void {
    var y: usize = 0;
    while (y < height) : (y += 1) {
        var x: usize = 0;
        while (x < width) : (x += 1) {
            const source_index = y * pitch + x;
            const dest_index = y * width + x;
            if (source_index >= indexed_pixels.len or dest_index >= argb_pixels.len) return;
            const entry = palette[indexed_pixels[source_index]];
            argb_pixels[dest_index] = (@as(u32, 0xff) << 24) |
                (@as(u32, entry.peRed) << 16) |
                (@as(u32, entry.peGreen) << 8) |
                @as(u32, entry.peBlue);
        }
    }
}

test "indexed pixels expand through palette to ARGB pixels" {
    var palette = [_]PaletteEntry{.{ .peRed = 0, .peGreen = 0, .peBlue = 0, .peFlags = 0 }} ** 256;
    palette[1] = .{ .peRed = 0x11, .peGreen = 0x22, .peBlue = 0x33, .peFlags = 0 };
    palette[2] = .{ .peRed = 0xaa, .peGreen = 0xbb, .peBlue = 0xcc, .peFlags = 0 };

    const indexed = [_]u8{ 1, 2 };
    var argb = [_]u32{0} ** indexed.len;

    expandIndexedToArgb(indexed[0..], 2, palette[0..], argb[0..]);

    try std.testing.expectEqual(@as(u32, 0xff112233), argb[0]);
    try std.testing.expectEqual(@as(u32, 0xffaabbcc), argb[1]);
}

test "indexed pixels expand by visible width while honoring source pitch" {
    var palette = [_]PaletteEntry{.{ .peRed = 0, .peGreen = 0, .peBlue = 0, .peFlags = 0 }} ** 256;
    palette[1] = .{ .peRed = 1, .peGreen = 0, .peBlue = 0, .peFlags = 0 };
    palette[2] = .{ .peRed = 2, .peGreen = 0, .peBlue = 0, .peFlags = 0 };
    palette[3] = .{ .peRed = 3, .peGreen = 0, .peBlue = 0, .peFlags = 0 };
    palette[4] = .{ .peRed = 4, .peGreen = 0, .peBlue = 0, .peFlags = 0 };
    palette[99] = .{ .peRed = 99, .peGreen = 0, .peBlue = 0, .peFlags = 0 };

    const indexed = [_]u8{
        1, 2, 99, 99,
        3, 4, 99, 99,
    };
    var argb = [_]u32{0} ** 4;

    expandIndexedRectToArgb(indexed[0..], 4, 2, 2, palette[0..], argb[0..]);

    try std.testing.expectEqual(@as(u32, 0xff010000), argb[0]);
    try std.testing.expectEqual(@as(u32, 0xff020000), argb[1]);
    try std.testing.expectEqual(@as(u32, 0xff030000), argb[2]);
    try std.testing.expectEqual(@as(u32, 0xff040000), argb[3]);
}
