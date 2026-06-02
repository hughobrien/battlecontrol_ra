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

const PumpEventCallback = *const fn (kind: u32, value: u32, x: i32, y: i32) callconv(.c) void;
const PUMP_EVENT_KEY_DOWN: u32 = 1;
const PUMP_EVENT_KEY_UP: u32 = 2;
const PUMP_EVENT_QUIT: u32 = 3;
const PUMP_EVENT_MOUSE_MOTION: u32 = 4;
const PUMP_EVENT_MOUSE_BUTTON_DOWN: u32 = 5;
const PUMP_EVENT_MOUSE_BUTTON_UP: u32 = 6;

extern fn getenv(name: [*:0]const u8) ?[*:0]const u8;

pub const Backend = struct {
    width: u32 = 0,
    height: u32 = 0,
    window: ?*c.SDL_Window = null,
    renderer: ?*c.SDL_Renderer = null,
    texture: ?*c.SDL_Texture = null,
    argb_pixels: []u32 = &.{},
    capture_written: bool = false,
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
        self.captureFrameOnce();
        if (!c.SDL_UpdateTexture(self.texture.?, null, self.argb_pixels.ptr, @intCast(width * @sizeOf(u32)))) {
            return error.SdlFailed;
        }
        _ = c.SDL_RenderClear(self.renderer.?);
        if (!c.SDL_RenderTexture(self.renderer.?, self.texture.?, null, null)) return error.SdlFailed;
        if (!c.SDL_RenderPresent(self.renderer.?)) return error.SdlFailed;
    }

    fn captureFrameOnce(self: *Backend) void {
        if (self.capture_written) return;

        const raw_path = getenv("RA_CAPTURE_BMP_FILE") orelse return;
        const path = std.mem.span(raw_path);
        if (path.len == 0) return;
        if (!argbPixelsHaveVisibleColor(self.argb_pixels)) return;

        self.capture_written = true;
        const io = std.Io.Threaded.global_single_threaded.io();
        writeBmpFromArgb(io, std.Io.Dir.cwd(), path, self.argb_pixels, self.width, self.height) catch return;
        writeCaptureReady() catch {};
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
                    callback(PUMP_EVENT_KEY_DOWN, virtual_key, 0, 0);
                    event_count += 1;
                }
            },
            c.SDL_EVENT_KEY_UP => {
                if (sdlKeyToVirtualKey(event.key.key)) |virtual_key| {
                    callback(PUMP_EVENT_KEY_UP, virtual_key, 0, 0);
                    event_count += 1;
                }
            },
            c.SDL_EVENT_QUIT => {
                callback(PUMP_EVENT_QUIT, 0, 0, 0);
                event_count += 1;
            },
            c.SDL_EVENT_MOUSE_MOTION => {
                callback(PUMP_EVENT_MOUSE_MOTION, 0, sdlCoordinateToI32(event.motion.x), sdlCoordinateToI32(event.motion.y));
                event_count += 1;
            },
            c.SDL_EVENT_MOUSE_BUTTON_DOWN => {
                if (sdlMouseButtonToVirtualKey(event.button.button)) |virtual_key| {
                    callback(PUMP_EVENT_MOUSE_BUTTON_DOWN, virtual_key, sdlCoordinateToI32(event.button.x), sdlCoordinateToI32(event.button.y));
                    event_count += 1;
                }
            },
            c.SDL_EVENT_MOUSE_BUTTON_UP => {
                if (sdlMouseButtonToVirtualKey(event.button.button)) |virtual_key| {
                    callback(PUMP_EVENT_MOUSE_BUTTON_UP, virtual_key, sdlCoordinateToI32(event.button.x), sdlCoordinateToI32(event.button.y));
                    event_count += 1;
                }
            },
            else => {},
        }
    }
    return event_count;
}

fn sdlCoordinateToI32(value: f32) i32 {
    if (!std.math.isFinite(value)) return 0;

    const min: f32 = @floatFromInt(std.math.minInt(i32));
    const max: f32 = @floatFromInt(std.math.maxInt(i32));
    if (value <= min) return std.math.minInt(i32);
    if (value >= max) return std.math.maxInt(i32);
    return @intFromFloat(value);
}

fn sdlMouseButtonToVirtualKey(button: u8) ?u32 {
    return switch (button) {
        c.SDL_BUTTON_LEFT => 0x01,
        c.SDL_BUTTON_RIGHT => 0x02,
        c.SDL_BUTTON_MIDDLE => 0x04,
        else => null,
    };
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

fn writeCaptureReady() !void {
    const raw_path = getenv("RA_CAPTURE_READY_FILE") orelse return;
    const path = std.mem.span(raw_path);
    if (path.len == 0) return;

    const io = std.Io.Threaded.global_single_threaded.io();
    var file = try std.Io.Dir.cwd().createFile(io, path, .{ .truncate = true });
    defer file.close(io);
    try file.writeStreamingAll(io, "frame=present\n");
}

fn argbPixelsHaveVisibleColor(argb_pixels: []const u32) bool {
    for (argb_pixels) |pixel| {
        if ((pixel & 0x00ffffff) != 0) return true;
    }
    return false;
}

fn writeBmpFromArgb(io: std.Io, dir: std.Io.Dir, path: []const u8, argb_pixels: []const u32, width: usize, height: usize) !void {
    if (width == 0 or height == 0) return error.InvalidDimensions;
    const pixel_count = try std.math.mul(usize, width, height);
    if (argb_pixels.len < pixel_count) return error.InvalidDimensions;

    const row_bytes = try std.math.mul(usize, width, 3);
    const row_stride = std.mem.alignForward(usize, row_bytes, 4);
    const pixel_bytes = try std.math.mul(usize, row_stride, height);
    const file_size = try std.math.add(usize, 54, pixel_bytes);
    if (file_size > std.math.maxInt(u32)) return error.InvalidDimensions;
    if (width > std.math.maxInt(i32) or height > std.math.maxInt(i32)) return error.InvalidDimensions;

    var file = try dir.createFile(io, path, .{ .truncate = true });
    defer file.close(io);

    var header = [_]u8{0} ** 54;
    header[0] = 'B';
    header[1] = 'M';
    std.mem.writeInt(u32, header[2..6], @intCast(file_size), .little);
    std.mem.writeInt(u32, header[10..14], 54, .little);
    std.mem.writeInt(u32, header[14..18], 40, .little);
    std.mem.writeInt(i32, header[18..22], @intCast(width), .little);
    std.mem.writeInt(i32, header[22..26], @intCast(height), .little);
    std.mem.writeInt(u16, header[26..28], 1, .little);
    std.mem.writeInt(u16, header[28..30], 24, .little);
    std.mem.writeInt(u32, header[34..38], @intCast(pixel_bytes), .little);
    try file.writeStreamingAll(io, &header);

    const padding_len = row_stride - row_bytes;
    const padding = [_]u8{0} ** 3;
    var y = height;
    while (y > 0) {
        y -= 1;
        var x: usize = 0;
        while (x < width) : (x += 1) {
            const pixel = argb_pixels[y * width + x];
            const bgr = [_]u8{
                @intCast(pixel & 0xff),
                @intCast((pixel >> 8) & 0xff),
                @intCast((pixel >> 16) & 0xff),
            };
            try file.writeStreamingAll(io, &bgr);
        }
        try file.writeStreamingAll(io, padding[0..padding_len]);
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

test "BMP writer stores ARGB pixels as bottom-up BGR rows" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const pixels = [_]u32{
        0xff112233, 0xff445566,
        0xff778899, 0xffaabbcc,
    };

    try writeBmpFromArgb(std.testing.io, tmp.dir, "capture.bmp", pixels[0..], 2, 2);

    const file = try tmp.dir.openFile(std.testing.io, "capture.bmp", .{});
    defer file.close(std.testing.io);

    var bytes: [70]u8 = undefined;
    try std.testing.expectEqual(bytes.len, try file.readPositionalAll(std.testing.io, &bytes, 0));

    try std.testing.expectEqualSlices(u8, "BM", bytes[0..2]);
    try std.testing.expectEqual(@as(u32, 70), std.mem.readInt(u32, bytes[2..6], .little));
    try std.testing.expectEqual(@as(u32, 54), std.mem.readInt(u32, bytes[10..14], .little));
    try std.testing.expectEqual(@as(i32, 2), std.mem.readInt(i32, bytes[18..22], .little));
    try std.testing.expectEqual(@as(i32, 2), std.mem.readInt(i32, bytes[22..26], .little));
    try std.testing.expectEqual(@as(u16, 24), std.mem.readInt(u16, bytes[28..30], .little));

    try std.testing.expectEqualSlices(u8, &.{ 0x99, 0x88, 0x77, 0xcc, 0xbb, 0xaa, 0, 0 }, bytes[54..62]);
    try std.testing.expectEqualSlices(u8, &.{ 0x33, 0x22, 0x11, 0x66, 0x55, 0x44, 0, 0 }, bytes[62..70]);
}

test "capture visibility check ignores alpha-only black frames" {
    try std.testing.expect(!argbPixelsHaveVisibleColor(&.{ 0xff000000, 0x00000000 }));
    try std.testing.expect(argbPixelsHaveVisibleColor(&.{ 0xff000000, 0xff000001 }));
}

const TestPumpedEvent = struct {
    kind: u32,
    value: u32,
    x: i32,
    y: i32,
};

var test_pumped_events = [_]TestPumpedEvent{.{ .kind = 0, .value = 0, .x = 0, .y = 0 }} ** 8;
var test_pumped_event_count: usize = 0;

fn recordPumpedEvent(kind: u32, value: u32, x: i32, y: i32) callconv(.c) void {
    test_pumped_events[test_pumped_event_count] = .{ .kind = kind, .value = value, .x = x, .y = y };
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
    try std.testing.expectEqual(@as(u32, 0x0d), test_pumped_events[0].value);
    try std.testing.expectEqual(@as(u32, 2), test_pumped_events[1].kind);
    try std.testing.expectEqual(@as(u32, 0x0d), test_pumped_events[1].value);
    try std.testing.expectEqual(@as(u32, 3), test_pumped_events[2].kind);
}

test "backend maps SDL mouse buttons to Win32 virtual keys" {
    try std.testing.expectEqual(@as(?u32, 0x01), sdlMouseButtonToVirtualKey(c.SDL_BUTTON_LEFT));
    try std.testing.expectEqual(@as(?u32, 0x02), sdlMouseButtonToVirtualKey(c.SDL_BUTTON_RIGHT));
    try std.testing.expectEqual(@as(?u32, 0x04), sdlMouseButtonToVirtualKey(c.SDL_BUTTON_MIDDLE));
    try std.testing.expectEqual(@as(?u32, null), sdlMouseButtonToVirtualKey(99));
}

test "backend pumps SDL mouse motion and button events" {
    _ = c.SDL_SetHint(c.SDL_HINT_VIDEO_DRIVER, "dummy");
    try std.testing.expect(c.SDL_Init(c.SDL_INIT_VIDEO));
    defer c.SDL_QuitSubSystem(c.SDL_INIT_VIDEO);

    var motion: c.SDL_Event = std.mem.zeroes(c.SDL_Event);
    motion.type = c.SDL_EVENT_MOUSE_MOTION;
    motion.motion.x = 12.5;
    motion.motion.y = 34.75;
    try std.testing.expect(c.SDL_PushEvent(&motion));

    var left_down: c.SDL_Event = std.mem.zeroes(c.SDL_Event);
    left_down.type = c.SDL_EVENT_MOUSE_BUTTON_DOWN;
    left_down.button.button = c.SDL_BUTTON_LEFT;
    left_down.button.x = 12.0;
    left_down.button.y = 34.0;
    try std.testing.expect(c.SDL_PushEvent(&left_down));

    var right_up: c.SDL_Event = std.mem.zeroes(c.SDL_Event);
    right_up.type = c.SDL_EVENT_MOUSE_BUTTON_UP;
    right_up.button.button = c.SDL_BUTTON_RIGHT;
    right_up.button.x = 56.0;
    right_up.button.y = 78.0;
    try std.testing.expect(c.SDL_PushEvent(&right_up));

    test_pumped_event_count = 0;
    try std.testing.expectEqual(@as(c_int, 3), ddrawMiniSdlPumpEvents(recordPumpedEvent));
    try std.testing.expectEqual(PUMP_EVENT_MOUSE_MOTION, test_pumped_events[0].kind);
    try std.testing.expectEqual(@as(i32, 12), test_pumped_events[0].x);
    try std.testing.expectEqual(@as(i32, 34), test_pumped_events[0].y);
    try std.testing.expectEqual(PUMP_EVENT_MOUSE_BUTTON_DOWN, test_pumped_events[1].kind);
    try std.testing.expectEqual(@as(u32, 0x01), test_pumped_events[1].value);
    try std.testing.expectEqual(@as(i32, 12), test_pumped_events[1].x);
    try std.testing.expectEqual(@as(i32, 34), test_pumped_events[1].y);
    try std.testing.expectEqual(PUMP_EVENT_MOUSE_BUTTON_UP, test_pumped_events[2].kind);
    try std.testing.expectEqual(@as(u32, 0x02), test_pumped_events[2].value);
    try std.testing.expectEqual(@as(i32, 56), test_pumped_events[2].x);
    try std.testing.expectEqual(@as(i32, 78), test_pumped_events[2].y);
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
