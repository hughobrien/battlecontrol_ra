const std = @import("std");

const BOOL = c_int;
const DWORD = u32;
const UINT = c_uint;
const LONG = c_long;
const LRESULT = isize;
const WORD = u16;
const ATOM = WORD;
const INT_PTR = isize;
const WPARAM = usize;
const LPARAM = isize;
const HANDLE = ?*anyopaque;
const HWND = ?*anyopaque;
const HMODULE = ?*anyopaque;
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

const POINT = extern struct {
    x: LONG,
    y: LONG,
};

const RECT = extern struct {
    left: LONG,
    top: LONG,
    right: LONG,
    bottom: LONG,
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
const SM_CXSCREEN: c_int = 0;
const SM_CYSCREEN: c_int = 1;
const TIME_PERIODIC: UINT = 0x0001;

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
var cursor_x: LONG = 0;
var cursor_y: LONG = 0;

export var WindowsNT: bool = false;

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

fn copyZ(dest: [*:0]u8, src: []const u8, max: usize) usize {
    if (max == 0) return 0;
    const count = @min(src.len, max - 1);
    @memcpy(dest[0..count], src[0..count]);
    dest[count] = 0;
    return count;
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
    _ = window;
    _ = message;
    _ = wparam;
    _ = lparam;
    return 1;
}

export fn PeekMessage(msg: ?*anyopaque, window: HWND, filter_min: UINT, filter_max: UINT, remove_msg: UINT) callconv(.c) BOOL {
    _ = msg;
    _ = window;
    _ = filter_min;
    _ = filter_max;
    _ = remove_msg;
    return 0;
}

export fn GetMessage(msg: ?*anyopaque, window: HWND, filter_min: UINT, filter_max: UINT) callconv(.c) BOOL {
    _ = msg;
    _ = window;
    _ = filter_min;
    _ = filter_max;
    return 0;
}

export fn TranslateMessage(msg: ?*const anyopaque) callconv(.c) BOOL {
    _ = msg;
    return 1;
}

export fn DispatchMessage(msg: ?*const anyopaque) callconv(.c) LRESULT {
    _ = msg;
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
    _ = exit_code;
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
    _ = window_class;
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
    return @ptrFromInt(1);
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
    out.x = cursor_x;
    out.y = cursor_y;
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
    _ = key;
    return 0;
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
