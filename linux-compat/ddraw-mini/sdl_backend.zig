const std = @import("std");

const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

comptime {
    if (c.SDL_VERSION < c.SDL_VERSIONNUM(3, 0, 0)) {
        @compileError("ddraw-mini SDL backend requires SDL3 headers");
    }
}

pub const PaletteEntry = extern struct {
    peRed: u8,
    peGreen: u8,
    peBlue: u8,
    peFlags: u8,
};

const PumpEventCallback = *const fn (kind: u32, key: u32) callconv(.c) void;
const PUMP_EVENT_KEY_DOWN: u32 = 1;
const PUMP_EVENT_KEY_UP: u32 = 2;
const PUMP_EVENT_QUIT: u32 = 3;

pub const Backend = struct {
    width: u32 = 0,
    height: u32 = 0,
    window: ?*c.SDL_Window = null,
    renderer: ?*c.SDL_Renderer = null,
    texture: ?*c.SDL_Texture = null,
    argb_pixels: []u32 = &.{},
    sdl_initialized: bool = false,

    pub fn initialize(self: *Backend, width: u32, height: u32) !void {
        if (width == 0 or height == 0) return error.InvalidDimensions;
        if (self.window != null and self.width == width and self.height == height) return;

        self.shutdown();

        if (!c.SDL_Init(c.SDL_INIT_VIDEO)) return error.SdlFailed;
        self.sdl_initialized = true;

        errdefer self.shutdown();

        const pixel_count = try std.math.mul(usize, width, height);
        self.argb_pixels = try std.heap.c_allocator.alloc(u32, pixel_count);
        @memset(self.argb_pixels, 0);

        self.window = c.SDL_CreateWindow("BattleControl Red Alert", @intCast(width), @intCast(height), 0) orelse return error.SdlFailed;
        self.renderer = c.SDL_CreateRenderer(self.window.?, null) orelse return error.SdlFailed;
        _ = c.SDL_SetRenderLogicalPresentation(self.renderer.?, @intCast(width), @intCast(height), c.SDL_LOGICAL_PRESENTATION_INTEGER_SCALE);
        self.texture = c.SDL_CreateTexture(
            self.renderer.?,
            c.SDL_PIXELFORMAT_ARGB8888,
            c.SDL_TEXTUREACCESS_STREAMING,
            @intCast(width),
            @intCast(height),
        ) orelse return error.SdlFailed;

        self.width = width;
        self.height = height;
    }

    pub fn shutdown(self: *Backend) void {
        if (self.texture) |texture| c.SDL_DestroyTexture(texture);
        if (self.renderer) |renderer| c.SDL_DestroyRenderer(renderer);
        if (self.window) |window| c.SDL_DestroyWindow(window);
        if (self.argb_pixels.len != 0) std.heap.c_allocator.free(self.argb_pixels);
        if (self.sdl_initialized) c.SDL_QuitSubSystem(c.SDL_INIT_VIDEO);
        self.* = .{};
    }

    pub fn presentIndexedSurface(
        self: *Backend,
        indexed_pixels: []const u8,
        pitch: usize,
        width: usize,
        height: usize,
        palette: []const PaletteEntry,
    ) !void {
        if (self.texture == null or self.renderer == null) return error.NotInitialized;
        if (width != self.width or height != self.height) return error.InvalidDimensions;
        if (palette.len < 256) return error.InvalidPalette;
        if (height != 0) {
            const source_len = try std.math.add(usize, try std.math.mul(usize, height - 1, pitch), width);
            if (source_len > indexed_pixels.len) return error.InvalidDimensions;
        }

        expandIndexedRectToArgb(indexed_pixels, pitch, width, height, palette, self.argb_pixels);
        if (!c.SDL_UpdateTexture(self.texture.?, null, self.argb_pixels.ptr, @intCast(width * @sizeOf(u32)))) {
            return error.SdlFailed;
        }
        _ = c.SDL_RenderClear(self.renderer.?);
        if (!c.SDL_RenderTexture(self.renderer.?, self.texture.?, null, null)) return error.SdlFailed;
        if (!c.SDL_RenderPresent(self.renderer.?)) return error.SdlFailed;
    }
};

var global_backend = Backend{};

export fn ddrawMiniSdlSetDisplayMode(width: u32, height: u32, bits_per_pixel: u32) callconv(.c) c_int {
    if (bits_per_pixel != 8) return 0;
    global_backend.initialize(width, height) catch return 0;
    return 1;
}

export fn ddrawMiniSdlShutdown() callconv(.c) void {
    global_backend.shutdown();
}

export fn ddrawMiniSdlPresentIndexedSurface(
    indexed_pixels: ?[*]const u8,
    pitch: usize,
    width: usize,
    height: usize,
    palette: ?[*]const PaletteEntry,
) callconv(.c) c_int {
    const pixels = indexed_pixels orelse return 0;
    const entries = palette orelse return 0;
    const source_len = if (height == 0) 0 else std.math.add(usize, std.math.mul(usize, height - 1, pitch) catch return 0, width) catch return 0;
    global_backend.presentIndexedSurface(pixels[0..source_len], pitch, width, height, entries[0..256]) catch return 0;
    return 1;
}

export fn ddrawMiniSdlPumpEvents(callback: PumpEventCallback) callconv(.c) c_int {
    var event_count: c_int = 0;
    var event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&event)) {
        switch (event.type) {
            c.SDL_EVENT_KEY_DOWN => {
                if (sdlKeyToVirtualKey(event.key.key)) |virtual_key| {
                    callback(PUMP_EVENT_KEY_DOWN, virtual_key);
                    event_count += 1;
                }
            },
            c.SDL_EVENT_KEY_UP => {
                if (sdlKeyToVirtualKey(event.key.key)) |virtual_key| {
                    callback(PUMP_EVENT_KEY_UP, virtual_key);
                    event_count += 1;
                }
            },
            c.SDL_EVENT_QUIT => {
                callback(PUMP_EVENT_QUIT, 0);
                event_count += 1;
            },
            else => {},
        }
    }
    return event_count;
}

fn sdlKeyToVirtualKey(key: c.SDL_Keycode) ?u32 {
    if (key >= 'a' and key <= 'z') return @intCast(key - ('a' - 'A'));
    if (key >= 'A' and key <= 'Z') return @intCast(key);
    if (key >= '0' and key <= '9') return @intCast(key);

    return switch (key) {
        c.SDLK_RETURN => 0x0d,
        c.SDLK_ESCAPE => 0x1b,
        c.SDLK_SPACE => 0x20,
        c.SDLK_TAB => 0x09,
        c.SDLK_LEFT => 0x25,
        c.SDLK_UP => 0x26,
        c.SDLK_RIGHT => 0x27,
        c.SDLK_DOWN => 0x28,
        else => null,
    };
}

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

test "backend creates SDL resources and presents indexed pixels" {
    _ = c.SDL_SetHint(c.SDL_HINT_VIDEO_DRIVER, "dummy");
    _ = c.SDL_SetHint(c.SDL_HINT_RENDER_DRIVER, "software");

    var backend = Backend{};
    try backend.initialize(2, 2);
    defer backend.shutdown();

    var palette = [_]PaletteEntry{.{ .peRed = 0, .peGreen = 0, .peBlue = 0, .peFlags = 0 }} ** 256;
    palette[1] = .{ .peRed = 0x11, .peGreen = 0x22, .peBlue = 0x33, .peFlags = 0 };
    palette[2] = .{ .peRed = 0x44, .peGreen = 0x55, .peBlue = 0x66, .peFlags = 0 };
    palette[3] = .{ .peRed = 0x77, .peGreen = 0x88, .peBlue = 0x99, .peFlags = 0 };
    palette[4] = .{ .peRed = 0xaa, .peGreen = 0xbb, .peBlue = 0xcc, .peFlags = 0 };

    const indexed = [_]u8{ 1, 2, 3, 4 };
    try backend.presentIndexedSurface(indexed[0..], 2, 2, 2, palette[0..]);

    try std.testing.expectEqual(@as(u32, 0xff112233), backend.argb_pixels[0]);
    try std.testing.expectEqual(@as(u32, 0xff445566), backend.argb_pixels[1]);
    try std.testing.expectEqual(@as(u32, 0xff778899), backend.argb_pixels[2]);
    try std.testing.expectEqual(@as(u32, 0xffaabbcc), backend.argb_pixels[3]);
}

const TestPumpedEvent = struct {
    kind: u32,
    key: u32,
};

var test_pumped_events = [_]TestPumpedEvent{.{ .kind = 0, .key = 0 }} ** 8;
var test_pumped_event_count: usize = 0;

fn recordPumpedEvent(kind: u32, key: u32) callconv(.c) void {
    test_pumped_events[test_pumped_event_count] = .{ .kind = kind, .key = key };
    test_pumped_event_count += 1;
}

test "backend pumps SDL keyboard and quit events" {
    _ = c.SDL_SetHint(c.SDL_HINT_VIDEO_DRIVER, "dummy");
    try std.testing.expect(c.SDL_Init(c.SDL_INIT_VIDEO));
    defer c.SDL_QuitSubSystem(c.SDL_INIT_VIDEO);

    var key_down: c.SDL_Event = std.mem.zeroes(c.SDL_Event);
    key_down.type = c.SDL_EVENT_KEY_DOWN;
    key_down.key.key = c.SDLK_RETURN;
    try std.testing.expect(c.SDL_PushEvent(&key_down));

    var key_up: c.SDL_Event = std.mem.zeroes(c.SDL_Event);
    key_up.type = c.SDL_EVENT_KEY_UP;
    key_up.key.key = c.SDLK_RETURN;
    try std.testing.expect(c.SDL_PushEvent(&key_up));

    var quit: c.SDL_Event = std.mem.zeroes(c.SDL_Event);
    quit.type = c.SDL_EVENT_QUIT;
    try std.testing.expect(c.SDL_PushEvent(&quit));

    test_pumped_event_count = 0;
    try std.testing.expectEqual(@as(c_int, 3), ddrawMiniSdlPumpEvents(recordPumpedEvent));
    try std.testing.expectEqual(@as(u32, 1), test_pumped_events[0].kind);
    try std.testing.expectEqual(@as(u32, 0x0d), test_pumped_events[0].key);
    try std.testing.expectEqual(@as(u32, 2), test_pumped_events[1].kind);
    try std.testing.expectEqual(@as(u32, 0x0d), test_pumped_events[1].key);
    try std.testing.expectEqual(@as(u32, 3), test_pumped_events[2].kind);
}

test "backend maps SDL keycodes to Win32 virtual keys" {
    try std.testing.expectEqual(@as(?u32, 0x41), sdlKeyToVirtualKey('a'));
    try std.testing.expectEqual(@as(?u32, 0x39), sdlKeyToVirtualKey('9'));
    try std.testing.expectEqual(@as(?u32, 0x25), sdlKeyToVirtualKey(c.SDLK_LEFT));
    try std.testing.expectEqual(@as(?u32, 0x26), sdlKeyToVirtualKey(c.SDLK_UP));
    try std.testing.expectEqual(@as(?u32, 0x27), sdlKeyToVirtualKey(c.SDLK_RIGHT));
    try std.testing.expectEqual(@as(?u32, 0x28), sdlKeyToVirtualKey(c.SDLK_DOWN));
    try std.testing.expectEqual(@as(?u32, null), sdlKeyToVirtualKey(c.SDLK_F1));
}
