const std = @import("std");

const BOOL = c_int;
const DWORD = u32;
const UINT = c_uint;
const LONG = c_long;
const WPARAM = usize;
const LPARAM = isize;
const HANDLE = ?*anyopaque;
const HWND = ?*anyopaque;
const HMODULE = ?*anyopaque;
const HKEY = ?*anyopaque;
const HSZ = ?*anyopaque;
const HCONV = ?*anyopaque;
const HDDEDATA = ?*anyopaque;
const PCONVCONTEXT = ?*anyopaque;
const BYTE = u8;

const ERROR_FILE_NOT_FOUND: LONG = 2;
const DMLERR_NO_ERROR: UINT = 0;
const IDOK: c_int = 1;
const IDYES: c_int = 6;
const MB_YESNO: UINT = 0x00000004;

const DdeString = extern struct {
    next: ?*DdeString,
    text: [1]u8,
};

var dde_strings: ?*DdeString = null;

extern fn readlink(path: [*:0]const u8, buffer: [*]u8, size: usize) isize;
extern fn usleep(usec: c_uint) c_int;

fn copyZ(dest: [*:0]u8, src: []const u8, max: usize) usize {
    if (max == 0) return 0;
    const count = @min(src.len, max - 1);
    @memcpy(dest[0..count], src[0..count]);
    dest[count] = 0;
    return count;
}

export fn lstrcpy(dest: [*:0]u8, src: [*:0]const u8) callconv(.c) [*:0]u8 {
    const text = std.mem.span(src);
    _ = copyZ(dest, text, text.len + 1);
    return dest;
}

export fn _Z13WWDebugStringPKc(string: ?[*:0]const u8) callconv(.c) void {
    _ = string;
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

export fn SetForegroundWindow(window: HWND) callconv(.c) BOOL {
    _ = window;
    return 0;
}

export fn ShowWindow(window: HWND, command_show: c_int) callconv(.c) BOOL {
    _ = window;
    _ = command_show;
    return 0;
}

export fn MessageBox(window: HWND, text: ?[*:0]const u8, caption: ?[*:0]const u8, kind: UINT) callconv(.c) c_int {
    _ = window;
    _ = text;
    _ = caption;
    if ((kind & MB_YESNO) != 0) return IDYES;
    return IDOK;
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
