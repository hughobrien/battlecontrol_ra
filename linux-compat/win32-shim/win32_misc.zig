const std = @import("std");

const BOOL = c_int;
const DWORD = u32;
const UINT = c_uint;
const LONG = c_long;
const HRESULT = LONG;
const LRESULT = isize;
const WORD = u16;
const ATOM = WORD;
const INT_PTR = isize;
const WPARAM = usize;
const LPARAM = isize;
const HANDLE = ?*anyopaque;
const HWND = ?*anyopaque;
const HMODULE = ?*anyopaque;
const FARPROC = ?*anyopaque;
const HICON = ?*anyopaque;
const HINSTANCE = ?*anyopaque;
const HMENU = ?*anyopaque;
const HKEY = ?*anyopaque;
const HSZ = ?*anyopaque;
const HCONV = ?*anyopaque;
const HDDEDATA = ?*anyopaque;
const PCONVCONTEXT = ?*anyopaque;
const BYTE = u8;
const TimerCallback = *const fn (event_id: UINT, reserved: UINT, user: DWORD, reserved1: DWORD, reserved2: DWORD) callconv(.c) void;
const WNDPROC = ?*const fn (window: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.c) LRESULT;

const Tm = extern struct {
    tm_sec: c_int,
    tm_min: c_int,
    tm_hour: c_int,
    tm_mday: c_int,
    tm_mon: c_int,
    tm_year: c_int,
    tm_wday: c_int,
    tm_yday: c_int,
    tm_isdst: c_int,
    tm_gmtoff: c_long,
    tm_zone: ?[*:0]const u8,
};

const SYSTEMTIME = extern struct {
    wYear: WORD,
    wMonth: WORD,
    wDayOfWeek: WORD,
    wDay: WORD,
    wHour: WORD,
    wMinute: WORD,
    wSecond: WORD,
    wMilliseconds: WORD,
};

extern fn localtime_r(timep: *const std.c.time_t, result: *Tm) ?*Tm;

const POINT = extern struct {
    x: LONG,
    y: LONG,
};

const MSG = extern struct {
    hwnd: HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
};

const RECT = extern struct {
    left: LONG,
    top: LONG,
    right: LONG,
    bottom: LONG,
};

const WNDCLASS = extern struct {
    style: UINT,
    lpfnWndProc: WNDPROC,
    cbClsExtra: c_int,
    cbWndExtra: c_int,
    hInstance: HINSTANCE,
    hIcon: HICON,
    hCursor: ?*anyopaque,
    hbrBackground: ?*anyopaque,
    lpszMenuName: ?[*:0]const u8,
    lpszClassName: ?[*:0]const u8,
};

const CriticalSectionState = struct {
    gate: std.atomic.Mutex = .unlocked,
    state_lock: std.atomic.Mutex = .unlocked,
    owner: std.Thread.Id = undefined,
    owner_valid: bool = false,
    recursion: usize = 0,
};

const ERROR_FILE_NOT_FOUND: LONG = 2;
const DMLERR_NO_ERROR: UINT = 0;
const IDOK: c_int = 1;
const IDYES: c_int = 6;
const MB_YESNO: UINT = 0x00000004;
const WM_QUIT: UINT = 0x0012;
const WM_KEYDOWN: UINT = 0x0100;
const WM_KEYUP: UINT = 0x0101;
const WM_LBUTTONDOWN: UINT = 0x0201;
const WM_LBUTTONUP: UINT = 0x0202;
const WM_RBUTTONDOWN: UINT = 0x0204;
const WM_RBUTTONUP: UINT = 0x0205;
const WM_MBUTTONDOWN: UINT = 0x0207;
const WM_MBUTTONUP: UINT = 0x0208;
const VK_LBUTTON: UINT = 0x01;
const VK_RBUTTON: UINT = 0x02;
const VK_MBUTTON: UINT = 0x04;
const PM_NOREMOVE: UINT = 0x0000;
const PM_REMOVE: UINT = 0x0001;
const SM_CXSCREEN: c_int = 0;
const SM_CYSCREEN: c_int = 1;
const TIME_PERIODIC: UINT = 0x0001;
const SDL_PUMP_EVENT_KEY_DOWN: u32 = 1;
const SDL_PUMP_EVENT_KEY_UP: u32 = 2;
const SDL_PUMP_EVENT_QUIT: u32 = 3;
const SDL_PUMP_EVENT_MOUSE_MOTION: u32 = 4;
const SDL_PUMP_EVENT_MOUSE_BUTTON_DOWN: u32 = 5;
const SDL_PUMP_EVENT_MOUSE_BUTTON_UP: u32 = 6;
const KEY_DOWN_STATE: i16 = @bitCast(@as(u16, 0x8000));
const MESSAGE_QUEUE_CAPACITY: usize = 256;
const INJECTED_KEY_CAPACITY: usize = 256;
const MIN_INJECTED_KEY_DELAY_MS: i64 = 1000;

const DdeString = extern struct {
    next: ?*DdeString,
    text: [1]u8,
};

const MemoryStatus = extern struct {
    dwLength: DWORD,
    dwMemoryLoad: DWORD,
    dwTotalPhys: DWORD,
    dwAvailPhys: DWORD,
    dwTotalPageFile: DWORD,
    dwAvailPageFile: DWORD,
    dwTotalVirtual: DWORD,
    dwAvailVirtual: DWORD,
};

var dde_strings: ?*DdeString = null;
var timer_mutex: std.atomic.Mutex = .unlocked;
var timers = [_]?*TimerEvent{null} ** 64;
var cursor_x = std.atomic.Value(LONG).init(0);
var cursor_y = std.atomic.Value(LONG).init(0);
var left_mouse_down = std.atomic.Value(bool).init(false);
var right_mouse_down = std.atomic.Value(bool).init(false);
var middle_mouse_down = std.atomic.Value(bool).init(false);
var message_mutex: std.atomic.Mutex = .unlocked;
var message_queue: [MESSAGE_QUEUE_CAPACITY]MSG = undefined;
var message_count: usize = 0;
var registered_window_proc: WNDPROC = null;
var main_window_handle: HWND = @ptrFromInt(1);
var injected_key_sequence_loaded = false;
var injected_keys: [INJECTED_KEY_CAPACITY]UINT = undefined;
var injected_key_count: usize = 0;
var injected_key_index: usize = 0;
var injected_key_delay_ms: i64 = MIN_INJECTED_KEY_DELAY_MS;
var injected_key_next_due_ms: i64 = 0;

export var CPUType: u8 = 0;

const TimerEvent = struct {
    id: UINT,
    delay_ms: UINT,
    callback: TimerCallback,
    user: DWORD,
    flags: UINT,
    active: std.atomic.Value(bool),
    thread: std.Thread,
};

fn lockTimerTable() void {
    while (!timer_mutex.tryLock()) {
        std.Thread.yield() catch {};
    }
}

fn lockAtomic(mutex: *std.atomic.Mutex) void {
    while (!mutex.tryLock()) {
        std.Thread.yield() catch {};
    }
}

extern fn readlink(path: [*:0]const u8, buffer: [*]u8, size: usize) isize;
extern fn usleep(usec: c_uint) c_int;
extern fn memmove(dest: ?*anyopaque, src: ?*const anyopaque, count: usize) ?*anyopaque;
extern fn getenv(name: [*:0]const u8) ?[*:0]const u8;
extern fn ddrawMiniSdlPumpEvents(callback: *const fn (kind: u32, value: u32, x: i32, y: i32) callconv(.c) void) callconv(.c) c_int;

fn copyZ(dest: [*:0]u8, src: []const u8, max: usize) usize {
    if (max == 0) return 0;
    const count = @min(src.len, max - 1);
    @memcpy(dest[0..count], src[0..count]);
    dest[count] = 0;
    return count;
}

fn makeMessage(window: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM) MSG {
    return .{
        .hwnd = window,
        .message = message,
        .wParam = wparam,
        .lParam = lparam,
        .time = 0,
        .pt = .{ .x = cursor_x.load(.monotonic), .y = cursor_y.load(.monotonic) },
    };
}

fn messageMatches(message: MSG, window: HWND, filter_min: UINT, filter_max: UINT) bool {
    if (window != null and message.hwnd != window) return false;
    if (filter_min == 0 and filter_max == 0) return true;
    return message.message >= filter_min and message.message <= filter_max;
}

fn findMessageIndex(window: HWND, filter_min: UINT, filter_max: UINT) ?usize {
    var index: usize = 0;
    while (index < message_count) : (index += 1) {
        if (messageMatches(message_queue[index], window, filter_min, filter_max)) return index;
    }
    return null;
}

fn removeMessageAt(index: usize) MSG {
    const message = message_queue[index];
    var copy_index = index;
    while (copy_index + 1 < message_count) : (copy_index += 1) {
        message_queue[copy_index] = message_queue[copy_index + 1];
    }
    message_count -= 1;
    return message;
}

fn enqueueMessage(message: MSG) BOOL {
    lockAtomic(&message_mutex);
    defer message_mutex.unlock();

    if (message_count == message_queue.len) return 0;
    message_queue[message_count] = message;
    message_count += 1;
    return 1;
}

fn dequeueMessage(window: HWND, filter_min: UINT, filter_max: UINT, remove: bool) ?MSG {
    lockAtomic(&message_mutex);
    defer message_mutex.unlock();

    const index = findMessageIndex(window, filter_min, filter_max) orelse return null;
    if (remove) return removeMessageAt(index);
    return message_queue[index];
}

fn resetMessageQueueForTest() void {
    lockAtomic(&message_mutex);
    defer message_mutex.unlock();

    message_count = 0;
    registered_window_proc = null;
    main_window_handle = @ptrFromInt(1);
    cursor_x.store(0, .monotonic);
    cursor_y.store(0, .monotonic);
    left_mouse_down.store(false, .monotonic);
    right_mouse_down.store(false, .monotonic);
    middle_mouse_down.store(false, .monotonic);
    injected_key_sequence_loaded = true;
    injected_key_count = 0;
    injected_key_index = 0;
    injected_key_delay_ms = MIN_INJECTED_KEY_DELAY_MS;
    injected_key_next_due_ms = 0;
}

fn parseVirtualKey(token: []const u8) ?UINT {
    const trimmed = std.mem.trim(u8, token, " \t\r\n");
    if (trimmed.len == 0) return null;

    if (trimmed.len == 1) {
        const ch = trimmed[0];
        if (ch >= 'a' and ch <= 'z') return @as(UINT, ch - ('a' - 'A'));
        if (ch >= 'A' and ch <= 'Z') return @as(UINT, ch);
    }

    if (std.ascii.eqlIgnoreCase(trimmed, "ENTER") or std.ascii.eqlIgnoreCase(trimmed, "RETURN")) return 0x0d;
    if (std.ascii.eqlIgnoreCase(trimmed, "ESC") or std.ascii.eqlIgnoreCase(trimmed, "ESCAPE")) return 0x1b;
    if (std.ascii.eqlIgnoreCase(trimmed, "SPACE")) return 0x20;
    if (std.ascii.eqlIgnoreCase(trimmed, "TAB")) return 0x09;
    if (std.ascii.eqlIgnoreCase(trimmed, "UP")) return 0x26;
    if (std.ascii.eqlIgnoreCase(trimmed, "DOWN")) return 0x28;
    if (std.ascii.eqlIgnoreCase(trimmed, "LEFT")) return 0x25;
    if (std.ascii.eqlIgnoreCase(trimmed, "RIGHT")) return 0x27;

    if (trimmed.len > 2 and trimmed[0] == '0' and (trimmed[1] == 'x' or trimmed[1] == 'X')) {
        return std.fmt.parseInt(UINT, trimmed[2..], 16) catch null;
    }
    return std.fmt.parseInt(UINT, trimmed, 10) catch null;
}

fn currentTimeMs() i64 {
    return @intCast((monotonicNanoseconds() orelse 0) / std.time.ns_per_ms);
}

fn parseInjectedKeyDelayMs() i64 {
    const raw_delay = getenv("BATTLECONTROL_KEY_DELAY_MS") orelse return MIN_INJECTED_KEY_DELAY_MS;
    const parsed = std.fmt.parseInt(i64, std.mem.span(raw_delay), 10) catch return MIN_INJECTED_KEY_DELAY_MS;
    return @max(parsed, MIN_INJECTED_KEY_DELAY_MS);
}

fn configureInjectedKeySequence(keys: []const UINT, delay_ms: i64, first_due_ms: i64) void {
    injected_key_count = @min(keys.len, injected_keys.len);
    @memcpy(injected_keys[0..injected_key_count], keys[0..injected_key_count]);
    injected_key_index = 0;
    injected_key_delay_ms = @max(delay_ms, MIN_INJECTED_KEY_DELAY_MS);
    injected_key_next_due_ms = first_due_ms;
}

fn configureInjectedKeySequenceForTest(keys: []const UINT, delay_ms: i64, first_due_ms: i64) void {
    injected_key_sequence_loaded = true;
    configureInjectedKeySequence(keys, delay_ms, first_due_ms);
}

fn loadInjectedKeySequenceOnce(now_ms: i64) void {
    if (injected_key_sequence_loaded) return;
    injected_key_sequence_loaded = true;

    const raw_sequence = getenv("BATTLECONTROL_KEY_SEQUENCE") orelse return;
    var parsed_keys: [INJECTED_KEY_CAPACITY]UINT = undefined;
    var parsed_count: usize = 0;
    var tokens = std.mem.tokenizeAny(u8, std.mem.span(raw_sequence), ",; \t\r\n");
    while (tokens.next()) |token| {
        const virtual_key = parseVirtualKey(token) orelse continue;
        if (parsed_count == parsed_keys.len) break;
        parsed_keys[parsed_count] = virtual_key;
        parsed_count += 1;
    }
    const delay_ms = parseInjectedKeyDelayMs();
    configureInjectedKeySequence(parsed_keys[0..parsed_count], delay_ms, now_ms + delay_ms);
}

fn pumpInjectedKeySequence(now_ms: i64) void {
    loadInjectedKeySequenceOnce(now_ms);
    if (injected_key_index >= injected_key_count) return;
    if (now_ms < injected_key_next_due_ms) return;

    const virtual_key = injected_keys[injected_key_index];
    injected_key_index += 1;
    injected_key_next_due_ms = now_ms + injected_key_delay_ms;
    _ = enqueueMessage(makeMessage(main_window_handle, WM_KEYDOWN, virtual_key, 0));
    _ = enqueueMessage(makeMessage(main_window_handle, WM_KEYUP, virtual_key, 0));
}

fn updateCursorPosition(x: i32, y: i32) void {
    cursor_x.store(x, .monotonic);
    cursor_y.store(y, .monotonic);
}

fn packMouseLParam(x: i32, y: i32) LPARAM {
    const low: u16 = @truncate(@as(u32, @bitCast(x)));
    const high: u16 = @truncate(@as(u32, @bitCast(y)));
    return @intCast(@as(u32, low) | (@as(u32, high) << 16));
}

fn updateMouseButtonState(key: u32, down: bool) void {
    switch (key) {
        VK_LBUTTON => left_mouse_down.store(down, .monotonic),
        VK_RBUTTON => right_mouse_down.store(down, .monotonic),
        VK_MBUTTON => middle_mouse_down.store(down, .monotonic),
        else => {},
    }
}

fn mouseButtonMessage(kind: u32, key: u32) ?UINT {
    return switch (kind) {
        SDL_PUMP_EVENT_MOUSE_BUTTON_DOWN => switch (key) {
            VK_LBUTTON => WM_LBUTTONDOWN,
            VK_RBUTTON => WM_RBUTTONDOWN,
            VK_MBUTTON => WM_MBUTTONDOWN,
            else => null,
        },
        SDL_PUMP_EVENT_MOUSE_BUTTON_UP => switch (key) {
            VK_LBUTTON => WM_LBUTTONUP,
            VK_RBUTTON => WM_RBUTTONUP,
            VK_MBUTTON => WM_MBUTTONUP,
            else => null,
        },
        else => null,
    };
}

fn queueSdlPumpEvent(kind: u32, value: u32, x: i32, y: i32) callconv(.c) void {
    switch (kind) {
        SDL_PUMP_EVENT_KEY_DOWN => _ = enqueueMessage(makeMessage(main_window_handle, WM_KEYDOWN, value, 0)),
        SDL_PUMP_EVENT_KEY_UP => _ = enqueueMessage(makeMessage(main_window_handle, WM_KEYUP, value, 0)),
        SDL_PUMP_EVENT_QUIT => _ = enqueueMessage(makeMessage(null, WM_QUIT, 0, 0)),
        SDL_PUMP_EVENT_MOUSE_MOTION => updateCursorPosition(x, y),
        SDL_PUMP_EVENT_MOUSE_BUTTON_DOWN, SDL_PUMP_EVENT_MOUSE_BUTTON_UP => {
            if (mouseButtonMessage(kind, value)) |message| {
                updateCursorPosition(x, y);
                updateMouseButtonState(value, kind == SDL_PUMP_EVENT_MOUSE_BUTTON_DOWN);
                _ = enqueueMessage(makeMessage(main_window_handle, message, 0, packMouseLParam(x, y)));
            }
        },
        else => {},
    }
}

fn pumpSdlEvents() void {
    _ = ddrawMiniSdlPumpEvents(queueSdlPumpEvent);
}

fn readLe16(ptr: [*]const u8) usize {
    return @as(usize, ptr[0]) | (@as(usize, ptr[1]) << 8);
}

export fn lstrcpy(dest: [*:0]u8, src: [*:0]const u8) callconv(.c) [*:0]u8 {
    const text = std.mem.span(src);
    _ = copyZ(dest, text, text.len + 1);
    return dest;
}

export fn GetModuleFileName(module: HMODULE, filename: [*:0]u8, size: DWORD) callconv(.c) DWORD {
    _ = module;
    if (size == 0) return 0;

    const rc = readlink("/proc/self/exe", filename, size - 1);
    if (rc < 0) {
        return @intCast(copyZ(filename, "ra", size));
    }
    filename[@intCast(rc)] = 0;
    return @intCast(rc);
}

export fn GetVersion() callconv(.c) DWORD {
    return 0x80000000 | 4;
}

export fn LoadLibrary(library_name: ?[*:0]const u8) callconv(.c) HINSTANCE {
    _ = library_name;
    return null;
}

export fn GetProcAddress(module: HMODULE, procedure_name: ?[*:0]const u8) callconv(.c) FARPROC {
    _ = module;
    _ = procedure_name;
    return null;
}

export fn FreeLibrary(module: HMODULE) callconv(.c) BOOL {
    _ = module;
    return 0;
}

export fn FindWindow(class_name: ?[*:0]const u8, window_name: ?[*:0]const u8) callconv(.c) HWND {
    _ = class_name;
    _ = window_name;
    return null;
}

export fn IsWindow(window: HWND) callconv(.c) BOOL {
    _ = window;
    return 0;
}

export fn PostMessage(window: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.c) BOOL {
    return enqueueMessage(makeMessage(window, message, wparam, lparam));
}

export fn PeekMessage(msg: ?*MSG, window: HWND, filter_min: UINT, filter_max: UINT, remove_msg: UINT) callconv(.c) BOOL {
    pumpSdlEvents();
    pumpInjectedKeySequence(currentTimeMs());
    const message = dequeueMessage(window, filter_min, filter_max, (remove_msg & PM_REMOVE) != PM_NOREMOVE) orelse return 0;
    if (msg) |out| out.* = message;
    return 1;
}

export fn GetMessage(msg: ?*MSG, window: HWND, filter_min: UINT, filter_max: UINT) callconv(.c) BOOL {
    pumpSdlEvents();
    pumpInjectedKeySequence(currentTimeMs());
    const message = dequeueMessage(window, filter_min, filter_max, true) orelse return 0;
    if (msg) |out| out.* = message;
    if (message.message == WM_QUIT) return 0;
    return 1;
}

export fn TranslateMessage(msg: ?*const MSG) callconv(.c) BOOL {
    _ = msg;
    return 1;
}

export fn DispatchMessage(msg: ?*const MSG) callconv(.c) LRESULT {
    const message = msg orelse return 0;
    if (message.hwnd == null) return 0;
    if (registered_window_proc) |window_proc| {
        return window_proc(message.hwnd, message.message, message.wParam, message.lParam);
    }
    return 0;
}

export fn DefWindowProc(window: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.c) LRESULT {
    _ = window;
    _ = message;
    _ = wparam;
    _ = lparam;
    return 0;
}

export fn PostQuitMessage(exit_code: c_int) callconv(.c) void {
    _ = enqueueMessage(makeMessage(null, WM_QUIT, @intCast(exit_code), 0));
}

export fn ExitProcess(exit_code: UINT) callconv(.c) void {
    std.process.exit(@intCast(exit_code & 0xff));
}

export fn SetForegroundWindow(window: HWND) callconv(.c) BOOL {
    _ = window;
    return 0;
}

export fn ShowWindow(window: HWND, command_show: c_int) callconv(.c) BOOL {
    _ = window;
    _ = command_show;
    return 0;
}

export fn LoadIcon(instance: HINSTANCE, icon_name: ?[*:0]const u8) callconv(.c) HICON {
    _ = instance;
    _ = icon_name;
    return null;
}

export fn RegisterClass(window_class: ?*const anyopaque) callconv(.c) ATOM {
    const class: *const WNDCLASS = @ptrCast(@alignCast(window_class orelse return 0));
    registered_window_proc = class.lpfnWndProc;
    return 1;
}

export fn CreateWindowEx(
    ex_style: DWORD,
    class_name: ?[*:0]const u8,
    window_name: ?[*:0]const u8,
    style: DWORD,
    x: c_int,
    y: c_int,
    width: c_int,
    height: c_int,
    parent: HWND,
    menu: HMENU,
    instance: HINSTANCE,
    param: ?*anyopaque,
) callconv(.c) HWND {
    _ = ex_style;
    _ = class_name;
    _ = window_name;
    _ = style;
    _ = x;
    _ = y;
    _ = width;
    _ = height;
    _ = parent;
    _ = menu;
    _ = instance;
    _ = param;
    main_window_handle = @ptrFromInt(1);
    return main_window_handle;
}

export fn GetSystemMetrics(index: c_int) callconv(.c) c_int {
    return switch (index) {
        SM_CXSCREEN => 640,
        SM_CYSCREEN => 480,
        else => 0,
    };
}

export fn UpdateWindow(window: HWND) callconv(.c) BOOL {
    _ = window;
    return 1;
}

export fn SetFocus(window: HWND) callconv(.c) HWND {
    return window;
}

export fn GetCursorPos(point: ?*POINT) callconv(.c) BOOL {
    const out = point orelse return 0;
    out.x = cursor_x.load(.monotonic);
    out.y = cursor_y.load(.monotonic);
    return 1;
}

export fn ClipCursor(rect: ?*const RECT) callconv(.c) BOOL {
    _ = rect;
    return 1;
}

export fn MapVirtualKey(code: UINT, map_type: UINT) callconv(.c) UINT {
    _ = map_type;
    return code;
}

export fn ToAscii(virtual_key: UINT, scan_code: UINT, key_state: ?[*]BYTE, translated: ?*WORD, flags: UINT) callconv(.c) c_int {
    _ = scan_code;
    _ = flags;
    const out = translated orelse return 0;
    const shifted = if (key_state) |state| (state[0x10] & 0x80) != 0 else false;
    var value: u8 = @truncate(virtual_key & 0xff);
    if (value >= 'A' and value <= 'Z') {
        if (!shifted) value = value - 'A' + 'a';
    }
    out.* = value;
    return 1;
}

export fn GetKeyState(key: c_int) callconv(.c) i16 {
    _ = key;
    return 0;
}

export fn GetAsyncKeyState(key: c_int) callconv(.c) i16 {
    return switch (@as(UINT, @intCast(key & 0xff))) {
        VK_LBUTTON => if (left_mouse_down.load(.monotonic)) KEY_DOWN_STATE else 0,
        VK_RBUTTON => if (right_mouse_down.load(.monotonic)) KEY_DOWN_STATE else 0,
        VK_MBUTTON => if (middle_mouse_down.load(.monotonic)) KEY_DOWN_STATE else 0,
        else => 0,
    };
}

export fn InitializeCriticalSection(critical_section: ?*anyopaque) callconv(.c) void {
    const section: ?*extern struct {
        DebugInfo: ?*anyopaque,
        LockCount: i32,
        RecursionCount: i32,
        OwningThread: HANDLE,
        LockSemaphore: HANDLE,
        SpinCount: usize,
    } = @ptrCast(@alignCast(critical_section));
    const out = section orelse return;
    const state = std.heap.c_allocator.create(CriticalSectionState) catch return;
    state.* = .{};
    out.DebugInfo = state;
    out.LockCount = -1;
    out.RecursionCount = 0;
    out.OwningThread = null;
    out.LockSemaphore = null;
    out.SpinCount = 0;
}

export fn DeleteCriticalSection(critical_section: ?*anyopaque) callconv(.c) void {
    const section: ?*extern struct {
        DebugInfo: ?*anyopaque,
        LockCount: i32,
        RecursionCount: i32,
        OwningThread: HANDLE,
        LockSemaphore: HANDLE,
        SpinCount: usize,
    } = @ptrCast(@alignCast(critical_section));
    const out = section orelse return;
    const state: *CriticalSectionState = @ptrCast(@alignCast(out.DebugInfo orelse return));
    std.heap.c_allocator.destroy(state);
    out.DebugInfo = null;
}

export fn EnterCriticalSection(critical_section: ?*anyopaque) callconv(.c) void {
    const section: ?*extern struct {
        DebugInfo: ?*anyopaque,
        LockCount: i32,
        RecursionCount: i32,
        OwningThread: HANDLE,
        LockSemaphore: HANDLE,
        SpinCount: usize,
    } = @ptrCast(@alignCast(critical_section));
    const out = section orelse return;
    const state: *CriticalSectionState = @ptrCast(@alignCast(out.DebugInfo orelse return));
    const thread_id = std.Thread.getCurrentId();
    lockAtomic(&state.state_lock);
    if (state.owner_valid and state.owner == thread_id) {
        state.recursion += 1;
        out.RecursionCount = @intCast(state.recursion);
        state.state_lock.unlock();
        return;
    }
    state.state_lock.unlock();

    lockAtomic(&state.gate);
    lockAtomic(&state.state_lock);
    state.owner = thread_id;
    state.owner_valid = true;
    state.recursion = 1;
    out.LockCount = 0;
    out.RecursionCount = 1;
    state.state_lock.unlock();
}

export fn LeaveCriticalSection(critical_section: ?*anyopaque) callconv(.c) void {
    const section: ?*extern struct {
        DebugInfo: ?*anyopaque,
        LockCount: i32,
        RecursionCount: i32,
        OwningThread: HANDLE,
        LockSemaphore: HANDLE,
        SpinCount: usize,
    } = @ptrCast(@alignCast(critical_section));
    const out = section orelse return;
    const state: *CriticalSectionState = @ptrCast(@alignCast(out.DebugInfo orelse return));
    lockAtomic(&state.state_lock);
    if (state.recursion == 0) {
        state.state_lock.unlock();
        return;
    }
    state.recursion -= 1;
    out.RecursionCount = @intCast(state.recursion);
    if (state.recursion == 0) {
        state.owner_valid = false;
        out.LockCount = -1;
        state.state_lock.unlock();
        state.gate.unlock();
        return;
    }
    state.state_lock.unlock();
}

export fn RegisterWindowMessage(string: ?[*:0]const u8) callconv(.c) UINT {
    _ = string;
    return 0x0400 + 50;
}

export fn DialogBox(instance: HANDLE, template_name: ?[*:0]const u8, owner: HWND, dialog_proc: ?*const anyopaque) callconv(.c) INT_PTR {
    _ = instance;
    _ = template_name;
    _ = owner;
    _ = dialog_proc;
    return 0;
}

export fn ShowCursor(show: BOOL) callconv(.c) c_int {
    _ = show;
    return 0;
}

export fn MessageBox(window: HWND, text: ?[*:0]const u8, caption: ?[*:0]const u8, kind: UINT) callconv(.c) c_int {
    _ = window;
    _ = text;
    _ = caption;
    if ((kind & MB_YESNO) != 0) return IDYES;
    return IDOK;
}

fn clampDword(value: u64) DWORD {
    return if (value > std.math.maxInt(DWORD)) std.math.maxInt(DWORD) else @intCast(value);
}

export fn GlobalMemoryStatus(buffer: ?*MemoryStatus) callconv(.c) void {
    const out = buffer orelse return;
    var info: std.os.linux.Sysinfo = undefined;
    const result = std.os.linux.sysinfo(&info);
    const ok = std.os.linux.errno(result) == .SUCCESS;
    const unit: u64 = if (ok) info.mem_unit else 1;
    const total_phys = if (ok) @as(u64, info.totalram) * unit else 0;
    const avail_phys = if (ok) @as(u64, info.freeram) * unit else total_phys;
    out.dwLength = @sizeOf(MemoryStatus);
    out.dwTotalPhys = clampDword(total_phys);
    out.dwAvailPhys = clampDword(avail_phys);
    out.dwTotalPageFile = clampDword(total_phys + if (ok) @as(u64, info.totalswap) * unit else 0);
    out.dwAvailPageFile = clampDword(avail_phys + if (ok) @as(u64, info.freeswap) * unit else 0);
    out.dwTotalVirtual = out.dwTotalPhys;
    out.dwAvailVirtual = out.dwAvailPhys;
    out.dwMemoryLoad = if (total_phys > 0 and avail_phys <= total_phys)
        @intCast((100 * (total_phys - avail_phys)) / total_phys)
    else
        0;
}

export fn GetCurrentProcess() callconv(.c) HANDLE {
    return @ptrFromInt(1);
}

export fn GetCurrentThread() callconv(.c) HANDLE {
    return @ptrFromInt(2);
}

export fn DuplicateHandle(
    source_process: HANDLE,
    source_handle: HANDLE,
    target_process: HANDLE,
    target_handle: ?*HANDLE,
    desired_access: DWORD,
    inherit_handle: BOOL,
    options: DWORD,
) callconv(.c) BOOL {
    _ = source_process;
    _ = target_process;
    _ = desired_access;
    _ = inherit_handle;
    _ = options;
    if (target_handle) |out| out.* = source_handle;
    return 1;
}

export fn OutputDebugString(string: ?[*:0]const u8) callconv(.c) void {
    _ = string;
}

export fn GetSystemTime(system_time: ?*SYSTEMTIME) callconv(.c) void {
    const realtime_ns = realtimeNanoseconds() orelse 0;
    fillUtcSystemTime(system_time, realtime_ns / std.time.ns_per_ms);
}

export fn GetLocalTime(system_time: ?*SYSTEMTIME) callconv(.c) void {
    const out = system_time orelse return;
    const realtime_ns = realtimeNanoseconds() orelse 0;
    const unix_millis = realtime_ns / std.time.ns_per_ms;
    const seconds: std.c.time_t = @intCast(unix_millis / std.time.ms_per_s);
    var tm: Tm = undefined;
    if (localtime_r(&seconds, &tm) == null) {
        fillUtcSystemTime(system_time, unix_millis);
        return;
    }

    out.* = .{
        .wYear = @intCast(tm.tm_year + 1900),
        .wMonth = @intCast(tm.tm_mon + 1),
        .wDayOfWeek = @intCast(tm.tm_wday),
        .wDay = @intCast(tm.tm_mday),
        .wHour = @intCast(tm.tm_hour),
        .wMinute = @intCast(tm.tm_min),
        .wSecond = @intCast(tm.tm_sec),
        .wMilliseconds = @intCast(unix_millis % std.time.ms_per_s),
    };
}

fn fillUtcSystemTime(system_time: ?*SYSTEMTIME, unix_millis: u64) void {
    const out = system_time orelse return;
    const seconds = unix_millis / std.time.ms_per_s;
    const epoch_seconds = std.time.epoch.EpochSeconds{ .secs = seconds };
    const epoch_day = epoch_seconds.getEpochDay();
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const day_seconds = epoch_seconds.getDaySeconds();

    out.* = .{
        .wYear = year_day.year,
        .wMonth = @intCast(@intFromEnum(month_day.month)),
        .wDayOfWeek = @intCast((epoch_day.day + 4) % 7),
        .wDay = @as(WORD, month_day.day_index) + 1,
        .wHour = day_seconds.getHoursIntoDay(),
        .wMinute = day_seconds.getMinutesIntoHour(),
        .wSecond = day_seconds.getSecondsIntoMinute(),
        .wMilliseconds = @intCast(unix_millis % std.time.ms_per_s),
    };
}

export fn timeBeginPeriod(period: UINT) callconv(.c) UINT {
    _ = period;
    return 0;
}

export fn timeEndPeriod(period: UINT) callconv(.c) UINT {
    _ = period;
    return 0;
}

export fn timeGetTime() callconv(.c) DWORD {
    const ns = monotonicNanoseconds() orelse return 0;
    return @truncate(ns / std.time.ns_per_ms);
}

fn monotonicNanoseconds() ?u64 {
    var ts: std.c.timespec = undefined;
    if (std.c.clock_gettime(std.c.CLOCK.MONOTONIC, &ts) != 0) return null;
    return (@as(u64, @intCast(ts.sec)) * std.time.ns_per_s) + @as(u64, @intCast(ts.nsec));
}

fn realtimeNanoseconds() ?u64 {
    var ts: std.c.timespec = undefined;
    if (std.c.clock_gettime(std.c.CLOCK.REALTIME, &ts) != 0) return null;
    return (@as(u64, @intCast(ts.sec)) * std.time.ns_per_s) + @as(u64, @intCast(ts.nsec));
}

fn timespecFromNanoseconds(ns: u64) std.c.timespec {
    return .{
        .sec = @intCast(ns / std.time.ns_per_s),
        .nsec = @intCast(ns % std.time.ns_per_s),
    };
}

fn sleepUntilNanoseconds(deadline_ns: u64) void {
    const deadline = timespecFromNanoseconds(deadline_ns);
    while (std.c.clock_nanosleep(std.c.CLOCK.MONOTONIC, .{ .ABSTIME = true }, &deadline, null) == @intFromEnum(std.c.E.INTR)) {}
}

fn timerThread(event: *TimerEvent) void {
    const interval_ns = @as(u64, @max(@as(UINT, 1), event.delay_ms)) * std.time.ns_per_ms;
    var next_deadline = (monotonicNanoseconds() orelse 0) + interval_ns;
    while (event.active.load(.acquire)) {
        sleepUntilNanoseconds(next_deadline);
        if (!event.active.load(.acquire)) break;
        event.callback(event.id, 0, event.user, 0, 0);
        if ((event.flags & TIME_PERIODIC) == 0) break;

        // Keep the original periodic cadence; if the callback ran late, the
        // next loop dispatches overdue ticks instead of dropping them.
        next_deadline += interval_ns;
    }
    event.active.store(false, .release);
}

export fn timeSetEvent(delay: UINT, resolution: UINT, callback: ?TimerCallback, user: DWORD, flags: UINT) callconv(.c) UINT {
    _ = resolution;
    const cb = callback orelse return 0;

    lockTimerTable();
    var slot: ?usize = null;
    for (timers, 0..) |timer, index| {
        if (timer == null) {
            slot = index;
            break;
        }
    }
    if (slot == null) {
        timer_mutex.unlock();
        return 0;
    }

    const event = std.heap.c_allocator.create(TimerEvent) catch {
        timer_mutex.unlock();
        return 0;
    };
    event.* = .{
        .id = @intCast(slot.? + 1),
        .delay_ms = @max(@as(UINT, 1), delay),
        .callback = cb,
        .user = user,
        .flags = flags,
        .active = std.atomic.Value(bool).init(true),
        .thread = undefined,
    };
    event.thread = std.Thread.spawn(.{}, timerThread, .{event}) catch {
        std.heap.c_allocator.destroy(event);
        timer_mutex.unlock();
        return 0;
    };
    timers[slot.?] = event;
    timer_mutex.unlock();
    return event.id;
}

export fn timeKillEvent(timer_id: UINT) callconv(.c) UINT {
    if (timer_id == 0 or timer_id > timers.len) return 1;
    const index: usize = @intCast(timer_id - 1);

    lockTimerTable();
    const event = timers[index] orelse {
        timer_mutex.unlock();
        return 1;
    };
    timers[index] = null;
    event.active.store(false, .release);
    timer_mutex.unlock();

    event.thread.join();
    std.heap.c_allocator.destroy(event);
    return 0;
}

export fn RegOpenKeyEx(key: HKEY, sub_key: ?[*:0]const u8, options: DWORD, sam_desired: DWORD, result: ?*HKEY) callconv(.c) LONG {
    _ = key;
    _ = sub_key;
    _ = options;
    _ = sam_desired;
    if (result) |out| out.* = null;
    return ERROR_FILE_NOT_FOUND;
}

export fn RegQueryValue(key: HKEY, sub_key: ?[*:0]const u8, data: ?[*:0]u8, size: ?*LONG) callconv(.c) LONG {
    _ = key;
    _ = sub_key;
    _ = data;
    if (size) |out| out.* = 0;
    return ERROR_FILE_NOT_FOUND;
}

export fn RegQueryValueEx(key: HKEY, value_name: ?[*:0]const u8, reserved: ?*DWORD, kind: ?*DWORD, data: ?[*]BYTE, size: ?*DWORD) callconv(.c) LONG {
    _ = key;
    _ = value_name;
    _ = reserved;
    _ = kind;
    _ = data;
    if (size) |out| out.* = 0;
    return ERROR_FILE_NOT_FOUND;
}

export fn RegCloseKey(key: HKEY) callconv(.c) LONG {
    _ = key;
    return 0;
}

export fn _Z20Get_Registry_Sub_KeyPvPci(base_key: HKEY, search_key: ?[*:0]u8, close: BOOL) callconv(.c) HKEY {
    _ = base_key;
    _ = search_key;
    _ = close;
    return null;
}

export fn CreateProcess(
    application_name: ?[*:0]const u8,
    command_line: ?[*:0]u8,
    process_attributes: ?*anyopaque,
    thread_attributes: ?*anyopaque,
    inherit_handles: BOOL,
    creation_flags: DWORD,
    environment: ?*anyopaque,
    current_directory: ?[*:0]const u8,
    startup_info: ?*anyopaque,
    process_information: ?*anyopaque,
) callconv(.c) BOOL {
    _ = application_name;
    _ = command_line;
    _ = process_attributes;
    _ = thread_attributes;
    _ = inherit_handles;
    _ = creation_flags;
    _ = environment;
    _ = current_directory;
    _ = startup_info;
    _ = process_information;
    return 0;
}

export fn Sleep(milliseconds: DWORD) callconv(.c) void {
    _ = usleep(@intCast(@as(u64, milliseconds) * 1000));
}

export fn htonl(hostlong: DWORD) callconv(.c) DWORD {
    return std.mem.nativeToBig(DWORD, hostlong);
}

export fn ntohl(netlong: DWORD) callconv(.c) DWORD {
    return std.mem.bigToNative(DWORD, netlong);
}

export fn htons(hostshort: WORD) callconv(.c) WORD {
    return std.mem.nativeToBig(WORD, hostshort);
}

export fn ntohs(netshort: WORD) callconv(.c) WORD {
    return std.mem.bigToNative(WORD, netshort);
}

export fn Mem_Copy(source: ?*const anyopaque, dest: ?*anyopaque, bytes_to_copy: c_ulong) callconv(.c) void {
    const src = source orelse return;
    const dst = dest orelse return;
    if (@intFromPtr(src) == @intFromPtr(dst)) return;
    _ = memmove(dst, src, @intCast(bytes_to_copy));
}

export fn Force_VM_Page_In(buffer: ?[*]u8, length: c_int) callconv(.c) void {
    if (buffer == null or length <= 0) return;

    const bytes: usize = @intCast(length);
    var offset: usize = 0;
    while (offset < bytes) : (offset += 4096) {
        const page: *volatile u8 = &buffer.?[offset];
        page.* = page.*;
    }
}

export fn Apply_XOR_Delta(target: [*]u8, delta: [*]const u8) callconv(.c) c_uint {
    var dest = target;
    var src = delta;
    while (true) {
        const op_code = src[0];
        src += 1;
        if (op_code == 0) {
            var count = src[0];
            src += 1;
            const value = src[0];
            src += 1;
            while (count != 0) : (count -= 1) {
                dest[0] ^= value;
                dest += 1;
            }
        } else if (op_code < 0x80) {
            var count = op_code;
            while (count != 0) : (count -= 1) {
                dest[0] ^= src[0];
                dest += 1;
                src += 1;
            }
        } else {
            const short_skip = op_code - 0x80;
            if (short_skip != 0) {
                dest += short_skip;
                continue;
            }
            const word = @as(u16, src[0]) | (@as(u16, src[1]) << 8);
            src += 2;
            if (word == 0) return 0;
            if ((word & 0x8000) == 0) {
                dest += word;
                continue;
            }
            var count = word - 0x8000;
            if ((count & 0x4000) != 0) {
                count -= 0x4000;
                const value = src[0];
                src += 1;
                while (count != 0) : (count -= 1) {
                    dest[0] ^= value;
                    dest += 1;
                }
            } else {
                while (count != 0) : (count -= 1) {
                    dest[0] ^= src[0];
                    dest += 1;
                    src += 1;
                }
            }
        }
    }
}

export fn Apply_XOR_Delta_To_Page_Or_Viewport(target: [*]u8, delta: [*]const u8, width: c_int, nextrow: c_int, copy: c_int) callconv(.c) void {
    if (width <= 0 or nextrow <= 0) return;

    const row_width: usize = @intCast(width);
    const pitch: usize = @intCast(nextrow);
    const should_copy = copy != 0;
    var src = delta;
    var row_offset: usize = 0;
    var column: usize = 0;

    while (true) {
        const op_code = src[0];
        src += 1;
        if (op_code == 0) {
            var count = src[0];
            src += 1;
            const value = src[0];
            src += 1;
            while (count != 0) : (count -= 1) {
                applyDeltaByte(target, row_width, pitch, should_copy, &row_offset, &column, value);
            }
        } else if (op_code < 0x80) {
            var count = op_code;
            while (count != 0) : (count -= 1) {
                applyDeltaByte(target, row_width, pitch, should_copy, &row_offset, &column, src[0]);
                src += 1;
            }
        } else {
            const short_skip = op_code - 0x80;
            if (short_skip != 0) {
                skipDeltaBytes(row_width, pitch, &row_offset, &column, short_skip);
                continue;
            }
            const word = @as(u16, src[0]) | (@as(u16, src[1]) << 8);
            src += 2;
            if (word == 0) return;
            if ((word & 0x8000) == 0) {
                skipDeltaBytes(row_width, pitch, &row_offset, &column, word);
                continue;
            }
            var count = word - 0x8000;
            if ((count & 0x4000) != 0) {
                count -= 0x4000;
                const value = src[0];
                src += 1;
                while (count != 0) : (count -= 1) {
                    applyDeltaByte(target, row_width, pitch, should_copy, &row_offset, &column, value);
                }
            } else {
                while (count != 0) : (count -= 1) {
                    applyDeltaByte(target, row_width, pitch, should_copy, &row_offset, &column, src[0]);
                    src += 1;
                }
            }
        }
    }
}

fn applyDeltaByte(target: [*]u8, row_width: usize, pitch: usize, should_copy: bool, row_offset: *usize, column: *usize, value: u8) void {
    const dest_index = row_offset.* + column.*;
    if (should_copy) {
        target[dest_index] = value;
    } else {
        target[dest_index] ^= value;
    }

    column.* += 1;
    if (column.* == row_width) {
        column.* = 0;
        row_offset.* += pitch;
    }
}

fn skipDeltaBytes(row_width: usize, pitch: usize, row_offset: *usize, column: *usize, amount: usize) void {
    const total = column.* + amount;
    row_offset.* += (total / row_width) * pitch;
    column.* = total % row_width;
}

// LCW command semantics from WIN32LIB/IFF/LCWUNCMP.ASM; length is an output cap.
export fn LCW_Uncompress(source: [*]const u8, dest: [*]u8, length: c_ulong) callconv(.c) c_ulong {
    var src = source;
    var out = dest;
    const start = dest;
    const limit: usize = @intCast(length);
    var written: usize = 0;

    while (written < limit) {
        const max_count = limit - written;
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
            var count = @min(readLe16(src), max_count);
            const value = src[2];
            src += 3;
            written += count;
            while (count != 0) : (count -= 1) {
                out[0] = value;
                out += 1;
            }
        } else {
            var count = @as(usize, op_code & 0x3f) + 3;
            if (op_code == 0xff) {
                count = readLe16(src);
                src += 2;
            }
            const offset = readLe16(src);
            src += 2;
            count = @min(count, max_count);
            var copy = start + offset;
            written += count;
            while (count != 0) : (count -= 1) {
                out[0] = copy[0];
                out += 1;
                copy += 1;
            }
        }
    }

    return @intCast(written);
}

export fn DdeInitialize(instance: ?*DWORD, callback: ?*const anyopaque, command: DWORD, reserved: DWORD) callconv(.c) UINT {
    _ = callback;
    _ = command;
    _ = reserved;
    if (instance) |out| out.* = 1;
    return DMLERR_NO_ERROR;
}

export fn DdeCreateStringHandle(instance: DWORD, string: [*:0]const u8, code_page: c_int) callconv(.c) HSZ {
    _ = instance;
    _ = code_page;
    const text = std.mem.span(string);
    const mem = std.c.malloc(@sizeOf(DdeString) + text.len) orelse return null;
    const handle: *DdeString = @ptrCast(@alignCast(mem));
    handle.next = dde_strings;
    dde_strings = handle;
    const out: [*:0]u8 = @ptrCast(&handle.text);
    _ = copyZ(out, text, text.len + 1);
    return @ptrCast(handle);
}

export fn DdeUninitialize(instance: DWORD) callconv(.c) BOOL {
    _ = instance;
    while (dde_strings) |handle| {
        dde_strings = handle.next;
        std.c.free(handle);
    }
    return 1;
}

export fn DdeNameService(instance: DWORD, service: HSZ, reserved: HSZ, command: UINT) callconv(.c) HDDEDATA {
    _ = instance;
    _ = service;
    _ = reserved;
    _ = command;
    return null;
}

export fn DdeConnect(instance: DWORD, service: HSZ, topic: HSZ, context: PCONVCONTEXT) callconv(.c) HCONV {
    _ = instance;
    _ = service;
    _ = topic;
    _ = context;
    return null;
}

export fn DdeDisconnect(conversation: HCONV) callconv(.c) BOOL {
    _ = conversation;
    return 1;
}

export fn DdeClientTransaction(data: ?[*]BYTE, data_length: DWORD, conversation: HCONV, item: HSZ, format: UINT, transaction: UINT, timeout: DWORD, result: ?*DWORD) callconv(.c) HDDEDATA {
    _ = data;
    _ = data_length;
    _ = conversation;
    _ = item;
    _ = format;
    _ = transaction;
    _ = timeout;
    if (result) |out| out.* = 0;
    return null;
}

export fn DdeQueryString(instance: DWORD, string: HSZ, buffer: ?[*:0]u8, buffer_max: DWORD, code_page: c_int) callconv(.c) DWORD {
    _ = instance;
    _ = code_page;
    const handle: *DdeString = @ptrCast(@alignCast(string orelse return 0));
    const src: [*:0]const u8 = @ptrCast(&handle.text);
    const text = std.mem.span(src);
    if (buffer) |dest| {
        return @intCast(copyZ(dest, text, buffer_max));
    }
    return @intCast(text.len);
}

export fn DdeAccessData(data: HDDEDATA, data_size: ?*DWORD) callconv(.c) ?[*]BYTE {
    if (data_size) |out| out.* = 0;
    return @ptrCast(data);
}

export fn DdeUnaccessData(data: HDDEDATA) callconv(.c) BOOL {
    _ = data;
    return 1;
}

test "legacy DLL loading reports absent modules" {
    try std.testing.expectEqual(@as(HINSTANCE, null), LoadLibrary("THIPX32.DLL"));
}

test "procedure lookup fails for absent modules" {
    try std.testing.expectEqual(@as(FARPROC, null), GetProcAddress(null, "_IPX_Shut_Down95"));
}

test "legacy CPU type starts unknown" {
    try std.testing.expectEqual(@as(u8, 0), CPUType);
}

test "Win32 message queue preserves PeekMessage and GetMessage semantics" {
    resetMessageQueueForTest();

    try std.testing.expectEqual(@as(BOOL, 1), PostMessage(@ptrFromInt(1), 0x0100, 0x0d, 0x1234));

    var peeked: MSG = undefined;
    try std.testing.expectEqual(@as(BOOL, 1), PeekMessage(&peeked, null, 0, 0, PM_NOREMOVE));
    try std.testing.expectEqual(@as(HWND, @ptrFromInt(1)), peeked.hwnd);
    try std.testing.expectEqual(@as(UINT, 0x0100), peeked.message);
    try std.testing.expectEqual(@as(WPARAM, 0x0d), peeked.wParam);
    try std.testing.expectEqual(@as(LPARAM, 0x1234), peeked.lParam);

    var popped: MSG = undefined;
    try std.testing.expectEqual(@as(BOOL, 1), GetMessage(&popped, null, 0, 0));
    try std.testing.expectEqual(peeked, popped);
    try std.testing.expectEqual(@as(BOOL, 0), PeekMessage(&peeked, null, 0, 0, PM_NOREMOVE));
}

test "key sequence parser accepts menu-driving virtual key names and values" {
    try std.testing.expectEqual(@as(UINT, 0x0d), parseVirtualKey("ENTER").?);
    try std.testing.expectEqual(@as(UINT, 0x1b), parseVirtualKey("escape").?);
    try std.testing.expectEqual(@as(UINT, 0x41), parseVirtualKey("a").?);
    try std.testing.expectEqual(@as(UINT, 0x28), parseVirtualKey("0x28").?);
    try std.testing.expectEqual(@as(UINT, 27), parseVirtualKey("27").?);
    try std.testing.expectEqual(@as(?UINT, null), parseVirtualKey("not-a-key"));
}

test "injected key sequence is paced by at least the configured delay" {
    resetMessageQueueForTest();
    configureInjectedKeySequenceForTest(&.{ 0x0d, 0x1b }, 1000, 1000);

    pumpInjectedKeySequence(999);
    try std.testing.expectEqual(@as(?MSG, null), dequeueMessage(null, 0, 0, false));

    pumpInjectedKeySequence(1000);
    var message = dequeueMessage(null, 0, 0, true).?;
    try std.testing.expectEqual(WM_KEYDOWN, message.message);
    try std.testing.expectEqual(@as(WPARAM, 0x0d), message.wParam);
    message = dequeueMessage(null, 0, 0, true).?;
    try std.testing.expectEqual(WM_KEYUP, message.message);
    try std.testing.expectEqual(@as(WPARAM, 0x0d), message.wParam);

    pumpInjectedKeySequence(1999);
    try std.testing.expectEqual(@as(?MSG, null), dequeueMessage(null, 0, 0, false));

    pumpInjectedKeySequence(2000);
    message = dequeueMessage(null, 0, 0, true).?;
    try std.testing.expectEqual(WM_KEYDOWN, message.message);
    try std.testing.expectEqual(@as(WPARAM, 0x1b), message.wParam);
}

test "SDL pump callback queues Win32 keyboard and quit messages" {
    resetMessageQueueForTest();

    queueSdlPumpEvent(SDL_PUMP_EVENT_KEY_DOWN, 0x0d, 0, 0);
    queueSdlPumpEvent(SDL_PUMP_EVENT_KEY_UP, 0x0d, 0, 0);
    queueSdlPumpEvent(SDL_PUMP_EVENT_QUIT, 0, 0, 0);

    var message = dequeueMessage(null, 0, 0, true).?;
    try std.testing.expectEqual(WM_KEYDOWN, message.message);
    try std.testing.expectEqual(@as(WPARAM, 0x0d), message.wParam);

    message = dequeueMessage(null, 0, 0, true).?;
    try std.testing.expectEqual(WM_KEYUP, message.message);
    try std.testing.expectEqual(@as(WPARAM, 0x0d), message.wParam);

    message = dequeueMessage(null, 0, 0, true).?;
    try std.testing.expectEqual(WM_QUIT, message.message);
}

test "SDL mouse pump updates cursor and queues button messages" {
    resetMessageQueueForTest();

    queueSdlPumpEvent(SDL_PUMP_EVENT_MOUSE_MOTION, 0, 12, 34);

    var point: POINT = undefined;
    try std.testing.expectEqual(@as(BOOL, 1), GetCursorPos(&point));
    try std.testing.expectEqual(@as(LONG, 12), point.x);
    try std.testing.expectEqual(@as(LONG, 34), point.y);
    try std.testing.expectEqual(@as(?MSG, null), dequeueMessage(null, 0, 0, true));

    queueSdlPumpEvent(SDL_PUMP_EVENT_MOUSE_BUTTON_DOWN, VK_LBUTTON, 12, 34);
    try std.testing.expectEqual(@as(i16, @bitCast(@as(u16, 0x8000))), GetAsyncKeyState(VK_LBUTTON));

    var message = dequeueMessage(null, 0, 0, true).?;
    try std.testing.expectEqual(WM_LBUTTONDOWN, message.message);
    try std.testing.expectEqual(@as(WPARAM, 0), message.wParam);
    try std.testing.expectEqual(@as(LPARAM, 0x0022000c), message.lParam);
    try std.testing.expectEqual(@as(LONG, 12), message.pt.x);
    try std.testing.expectEqual(@as(LONG, 34), message.pt.y);

    queueSdlPumpEvent(SDL_PUMP_EVENT_MOUSE_BUTTON_UP, VK_LBUTTON, 13, 35);
    try std.testing.expectEqual(@as(i16, 0), GetAsyncKeyState(VK_LBUTTON));

    message = dequeueMessage(null, 0, 0, true).?;
    try std.testing.expectEqual(WM_LBUTTONUP, message.message);
    try std.testing.expectEqual(@as(LPARAM, 0x0023000d), message.lParam);
}

test "SDL mouse pump maps right and middle button messages" {
    resetMessageQueueForTest();

    queueSdlPumpEvent(SDL_PUMP_EVENT_MOUSE_BUTTON_DOWN, VK_RBUTTON, 56, 78);
    try std.testing.expectEqual(@as(i16, @bitCast(@as(u16, 0x8000))), GetAsyncKeyState(VK_RBUTTON));
    var message = dequeueMessage(null, 0, 0, true).?;
    try std.testing.expectEqual(WM_RBUTTONDOWN, message.message);
    try std.testing.expectEqual(@as(LPARAM, 0x004e0038), message.lParam);

    queueSdlPumpEvent(SDL_PUMP_EVENT_MOUSE_BUTTON_UP, VK_MBUTTON, 90, 123);
    try std.testing.expectEqual(@as(i16, 0), GetAsyncKeyState(VK_MBUTTON));
    message = dequeueMessage(null, 0, 0, true).?;
    try std.testing.expectEqual(WM_MBUTTONUP, message.message);
    try std.testing.expectEqual(@as(LPARAM, 0x007b005a), message.lParam);
}

var dispatched_message_for_test: UINT = 0;
var dispatched_wparam_for_test: WPARAM = 0;

fn testWindowProc(window: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.c) LRESULT {
    _ = window;
    _ = lparam;
    dispatched_message_for_test = message;
    dispatched_wparam_for_test = wparam;
    return 7;
}

test "DispatchMessage calls the window procedure registered by RegisterClass" {
    resetMessageQueueForTest();
    dispatched_message_for_test = 0;
    dispatched_wparam_for_test = 0;

    var class = WNDCLASS{
        .style = 0,
        .lpfnWndProc = testWindowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = null,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = null,
    };
    try std.testing.expectEqual(@as(ATOM, 1), RegisterClass(&class));

    var message = makeMessage(@ptrFromInt(1), WM_KEYDOWN, 0x0d, 0);
    try std.testing.expectEqual(@as(LRESULT, 7), DispatchMessage(&message));
    try std.testing.expectEqual(WM_KEYDOWN, dispatched_message_for_test);
    try std.testing.expectEqual(@as(WPARAM, 0x0d), dispatched_wparam_for_test);
}

test "system time fills Win32 SYSTEMTIME ranges" {
    var system_time: SYSTEMTIME = undefined;
    GetSystemTime(&system_time);

    try std.testing.expect(system_time.wYear >= 1970);
    try std.testing.expect(system_time.wMonth >= 1 and system_time.wMonth <= 12);
    try std.testing.expect(system_time.wDayOfWeek <= 6);
    try std.testing.expect(system_time.wDay >= 1 and system_time.wDay <= 31);
    try std.testing.expect(system_time.wHour <= 23);
    try std.testing.expect(system_time.wMinute <= 59);
    try std.testing.expect(system_time.wSecond <= 59);
    try std.testing.expect(system_time.wMilliseconds <= 999);
}

test "UTC system time conversion matches Win32 SYSTEMTIME fields" {
    var system_time: SYSTEMTIME = undefined;
    fillUtcSystemTime(&system_time, (1 * std.time.s_per_day + 2 * std.time.s_per_hour + 3 * std.time.s_per_min + 4) * std.time.ms_per_s + 567);

    try std.testing.expectEqual(@as(WORD, 1970), system_time.wYear);
    try std.testing.expectEqual(@as(WORD, 1), system_time.wMonth);
    try std.testing.expectEqual(@as(WORD, 5), system_time.wDayOfWeek);
    try std.testing.expectEqual(@as(WORD, 2), system_time.wDay);
    try std.testing.expectEqual(@as(WORD, 2), system_time.wHour);
    try std.testing.expectEqual(@as(WORD, 3), system_time.wMinute);
    try std.testing.expectEqual(@as(WORD, 4), system_time.wSecond);
    try std.testing.expectEqual(@as(WORD, 567), system_time.wMilliseconds);
}
