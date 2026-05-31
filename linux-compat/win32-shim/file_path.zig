const std = @import("std");

const DWORD = u32;
const BOOL = c_int;
const WORD = u16;
const LONG = c_long;
const UINT = c_uint;
const HANDLE = ?*anyopaque;

const INVALID_HANDLE_VALUE: HANDLE = @ptrFromInt(std.math.maxInt(usize));

const GENERIC_READ: DWORD = 0x80000000;
const GENERIC_WRITE: DWORD = 0x40000000;
const CREATE_ALWAYS: DWORD = 2;
const OPEN_EXISTING: DWORD = 3;
const FILE_BEGIN: DWORD = 0;
const FILE_CURRENT: DWORD = 1;
const FILE_END: DWORD = 2;

const O_RDONLY: c_int = 0;
const O_WRONLY: c_int = 1;
const O_RDWR: c_int = 2;
const O_CREAT: c_int = 0o100;
const O_TRUNC: c_int = 0o1000;
const SEEK_SET: c_int = 0;
const SEEK_CUR: c_int = 1;
const SEEK_END: c_int = 2;

const FileHandle = extern struct {
    fd: c_int,
};

const FILETIME = extern struct {
    dwLowDateTime: DWORD,
    dwHighDateTime: DWORD,
};

const BY_HANDLE_FILE_INFORMATION = extern struct {
    dwFileAttributes: DWORD,
    ftCreationTime: FILETIME,
    ftLastAccessTime: FILETIME,
    ftLastWriteTime: FILETIME,
    dwVolumeSerialNumber: DWORD,
    nFileSizeHigh: DWORD,
    nFileSizeLow: DWORD,
    nNumberOfLinks: DWORD,
    nFileIndexHigh: DWORD,
    nFileIndexLow: DWORD,
};

const DosFind = extern struct {
    attrib: c_uint,
    name: [260]u8,
};

const Timespec = extern struct {
    tv_sec: c_long,
    tv_nsec: c_long,
};

const Stat = extern struct {
    st_dev: c_ulong,
    st_ino: c_ulong,
    st_nlink: c_ulong,
    st_mode: c_uint,
    st_uid: c_uint,
    st_gid: c_uint,
    __pad0: c_int,
    st_rdev: c_ulong,
    st_size: c_long,
    st_blksize: c_long,
    st_blocks: c_long,
    st_atim: Timespec,
    st_mtim: Timespec,
    st_ctim: Timespec,
    __glibc_reserved: [3]c_long,
};

const DIR = opaque {};

const Dirent = extern struct {
    d_ino: c_ulong,
    d_off: c_long,
    d_reclen: c_ushort,
    d_type: u8,
    d_name: [256]u8,
};

const DT_DIR: u8 = 4;

const utimbuf = extern struct {
    actime: c_long,
    modtime: c_long,
};

extern fn open(pathname: [*:0]const u8, flags: c_int, mode: c_uint) c_int;
extern fn read(fd: c_int, buf: ?*anyopaque, count: usize) isize;
extern fn write(fd: c_int, buf: ?*const anyopaque, count: usize) isize;
extern fn close(fd: c_int) c_int;
extern fn lseek(fd: c_int, offset: c_long, whence: c_int) c_long;
extern fn unlink(pathname: [*:0]const u8) c_int;
extern fn utime(filename: [*:0]const u8, times: ?*const utimbuf) c_int;
extern fn fstat(fd: c_int, statbuf: *Stat) c_int;
extern fn opendir(name: [*:0]const u8) ?*DIR;
extern fn readdir(dirp: *DIR) ?*Dirent;
extern fn closedir(dirp: *DIR) c_int;

threadlocal var last_error: DWORD = 0;

fn setLastErrorFromErrno() void {
    last_error = @intCast(std.c._errno().*);
    if (last_error == 0) {
        last_error = 1;
    }
}

fn clearLastError() void {
    last_error = 0;
}

fn asHandle(handle: HANDLE) ?*FileHandle {
    if (handle == null or handle == INVALID_HANDLE_VALUE) return null;
    return @ptrCast(@alignCast(handle.?));
}

fn translatePath(path: [*:0]const u8, out: []u8) ?[:0]u8 {
    const in_path = std.mem.span(path);
    var index: usize = 0;
    var start: usize = 0;

    if (in_path.len >= 2 and in_path[1] == ':') {
        start = 2;
        if (start < in_path.len and (in_path[start] == '\\' or in_path[start] == '/')) {
            start += 1;
        }
    }

    if (start >= in_path.len) {
        if (out.len < 2) return null;
        out[0] = '.';
        out[1] = 0;
        return out[0..1 :0];
    }

    for (in_path[start..]) |ch| {
        if (index + 1 >= out.len) return null;
        out[index] = if (ch == '\\') '/' else ch;
        index += 1;
    }
    out[index] = 0;
    return out[0..index :0];
}

fn copyZ(dest: ?[*:0]u8, src: []const u8) void {
    if (dest == null) return;
    var i: usize = 0;
    while (i < src.len) : (i += 1) {
        dest.?[i] = src[i];
    }
    dest.?[i] = 0;
}

export fn _splitpath(path: [*:0]const u8, drive: ?[*:0]u8, dir: ?[*:0]u8, fname: ?[*:0]u8, ext: ?[*:0]u8) callconv(.c) void {
    const full = std.mem.span(path);
    if (drive) |d| {
        if (full.len >= 2 and full[1] == ':') {
            d[0] = full[0];
            d[1] = ':';
            d[2] = 0;
        } else {
            d[0] = 0;
        }
    }

    const start: usize = if (full.len >= 2 and full[1] == ':') 2 else 0;
    var slash: ?usize = null;
    var i: usize = start;
    while (i < full.len) : (i += 1) {
        if (full[i] == '/' or full[i] == '\\') slash = i;
    }

    var name_start = start;
    if (slash) |s| {
        name_start = s + 1;
        copyZ(dir, full[start..name_start]);
    } else {
        copyZ(dir, "");
    }

    var dot: ?usize = null;
    i = name_start;
    while (i < full.len) : (i += 1) {
        if (full[i] == '.') dot = i;
    }

    if (dot) |d| {
        copyZ(fname, full[name_start..d]);
        copyZ(ext, full[d..]);
    } else {
        copyZ(fname, full[name_start..]);
        copyZ(ext, "");
    }
}

export fn _makepath(path: [*:0]u8, drive: ?[*:0]const u8, dir: ?[*:0]const u8, fname: ?[*:0]const u8, ext: ?[*:0]const u8) callconv(.c) void {
    var index: usize = 0;
    const parts = [_]?[*:0]const u8{ drive, dir, fname, ext };
    for (parts) |part| {
        if (part) |p| {
            for (std.mem.span(p)) |ch| {
                path[index] = ch;
                index += 1;
            }
        }
    }
    path[index] = 0;
}

fn wildcardMatch(pattern: []const u8, name: []const u8) bool {
    var p: usize = 0;
    var n: usize = 0;
    var star: ?usize = null;
    var retry: usize = 0;

    while (n < name.len) {
        if (p < pattern.len and (pattern[p] == '?' or std.ascii.toLower(pattern[p]) == std.ascii.toLower(name[n]))) {
            p += 1;
            n += 1;
        } else if (p < pattern.len and pattern[p] == '*') {
            star = p;
            p += 1;
            retry = n;
        } else if (star) |s| {
            p = s + 1;
            retry += 1;
            n = retry;
        } else {
            return false;
        }
    }

    while (p < pattern.len and pattern[p] == '*') : (p += 1) {}
    return p == pattern.len;
}

export fn _dos_findfirst(filespec: [*:0]const u8, attrib: c_uint, fileinfo: ?*DosFind) callconv(.c) c_int {
    _ = attrib;
    var translated_buf: [1024]u8 = undefined;
    const translated = translatePath(filespec, &translated_buf) orelse {
        last_error = 1;
        return -1;
    };

    const path = translated[0..translated.len];
    var slash: ?usize = null;
    for (path, 0..) |ch, idx| {
        if (ch == '/') slash = idx;
    }

    const dir_name = if (slash) |s| path[0..s] else ".";
    const pattern = if (slash) |s| path[s + 1 ..] else path;
    const effective_pattern = if (pattern.len == 0) "*" else pattern;

    var dir_buf: [1024]u8 = undefined;
    const dir_path = std.fmt.bufPrintZ(&dir_buf, "{s}", .{dir_name}) catch {
        last_error = 206;
        return -1;
    };

    const dir = opendir(dir_path.ptr) orelse {
        setLastErrorFromErrno();
        return -1;
    };
    defer _ = closedir(dir);

    while (readdir(dir)) |entry| {
        const name = std.mem.sliceTo(entry.d_name[0..], 0);
        if (std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, "..")) {
            continue;
        }
        if (wildcardMatch(effective_pattern, name)) {
            if (fileinfo) |info| {
                info.attrib = if (entry.d_type == DT_DIR) 0x10 else 0;
                @memset(info.name[0..], 0);
                const count = @min(name.len, info.name.len - 1);
                @memcpy(info.name[0..count], name[0..count]);
            }
            clearLastError();
            return 0;
        }
    }

    last_error = 2;
    return -1;
}

export fn CreateFile(file_name: [*:0]const u8, desired_access: DWORD, share_mode: DWORD, security_attributes: ?*anyopaque, creation_disposition: DWORD, flags_and_attributes: DWORD, template_file: HANDLE) callconv(.c) HANDLE {
    _ = share_mode;
    _ = security_attributes;
    _ = flags_and_attributes;
    _ = template_file;

    var path_buf: [1024]u8 = undefined;
    const path = translatePath(file_name, &path_buf) orelse {
        last_error = 206;
        return INVALID_HANDLE_VALUE;
    };

    var flags: c_int = 0;
    if ((desired_access & GENERIC_WRITE) != 0 and (desired_access & GENERIC_READ) != 0) {
        flags = O_RDWR;
    } else if ((desired_access & GENERIC_WRITE) != 0) {
        flags = O_WRONLY;
    } else {
        flags = O_RDONLY;
    }

    switch (creation_disposition) {
        CREATE_ALWAYS => flags |= O_CREAT | O_TRUNC,
        OPEN_EXISTING => {},
        else => {},
    }

    const fd = open(path.ptr, flags, 0o666);
    if (fd < 0) {
        setLastErrorFromErrno();
        return INVALID_HANDLE_VALUE;
    }

    const mem = std.c.malloc(@sizeOf(FileHandle)) orelse {
        _ = close(fd);
        last_error = 8;
        return INVALID_HANDLE_VALUE;
    };
    const handle: *FileHandle = @ptrCast(@alignCast(mem));
    handle.fd = fd;
    clearLastError();
    return @ptrCast(handle);
}

export fn ReadFile(file: HANDLE, buffer: ?*anyopaque, bytes_to_read: DWORD, bytes_read: ?*DWORD, overlapped: ?*anyopaque) callconv(.c) BOOL {
    _ = overlapped;
    if (bytes_read) |out| out.* = 0;
    const handle = asHandle(file) orelse {
        last_error = 6;
        return 0;
    };
    const rc = read(handle.fd, buffer, bytes_to_read);
    if (rc < 0) {
        setLastErrorFromErrno();
        return 0;
    }
    if (bytes_read) |out| out.* = @intCast(rc);
    clearLastError();
    return 1;
}

export fn WriteFile(file: HANDLE, buffer: ?*const anyopaque, bytes_to_write: DWORD, bytes_written: ?*DWORD, overlapped: ?*anyopaque) callconv(.c) BOOL {
    _ = overlapped;
    if (bytes_written) |out| out.* = 0;
    const handle = asHandle(file) orelse {
        last_error = 6;
        return 0;
    };
    const rc = write(handle.fd, buffer, bytes_to_write);
    if (rc < 0) {
        setLastErrorFromErrno();
        return 0;
    }
    if (bytes_written) |out| out.* = @intCast(rc);
    clearLastError();
    return 1;
}

export fn CloseHandle(object: HANDLE) callconv(.c) BOOL {
    const handle = asHandle(object) orelse {
        last_error = 6;
        return 0;
    };
    const rc = close(handle.fd);
    std.c.free(handle);
    if (rc != 0) {
        setLastErrorFromErrno();
        return 0;
    }
    clearLastError();
    return 1;
}

export fn GetFileSize(file: HANDLE, file_size_high: ?*DWORD) callconv(.c) DWORD {
    if (file_size_high) |high| high.* = 0;
    const handle = asHandle(file) orelse {
        last_error = 6;
        return 0xffffffff;
    };
    var st: Stat = undefined;
    if (fstat(handle.fd, &st) != 0) {
        setLastErrorFromErrno();
        return 0xffffffff;
    }
    const size: u64 = @intCast(st.st_size);
    if (file_size_high) |high| high.* = @intCast(size >> 32);
    clearLastError();
    return @intCast(size & 0xffffffff);
}

export fn SetFilePointer(file: HANDLE, distance_to_move: LONG, distance_to_move_high: ?*LONG, move_method: DWORD) callconv(.c) DWORD {
    _ = distance_to_move_high;
    const handle = asHandle(file) orelse {
        last_error = 6;
        return 0xffffffff;
    };
    const whence: c_int = switch (move_method) {
        FILE_BEGIN => SEEK_SET,
        FILE_CURRENT => SEEK_CUR,
        FILE_END => SEEK_END,
        else => SEEK_SET,
    };
    const pos = lseek(handle.fd, distance_to_move, whence);
    if (pos < 0) {
        setLastErrorFromErrno();
        return 0xffffffff;
    }
    clearLastError();
    return @intCast(pos);
}

export fn DeleteFile(file_name: [*:0]const u8) callconv(.c) BOOL {
    var path_buf: [1024]u8 = undefined;
    const path = translatePath(file_name, &path_buf) orelse {
        last_error = 206;
        return 0;
    };
    if (unlink(path.ptr) != 0) {
        setLastErrorFromErrno();
        return 0;
    }
    clearLastError();
    return 1;
}

export fn GetLastError() callconv(.c) DWORD {
    return last_error;
}

export fn SetErrorMode(mode: UINT) callconv(.c) UINT {
    _ = mode;
    return 0;
}

fn unixSecondsToFileTime(seconds: i64) FILETIME {
    const intervals: u64 = @intCast((seconds + 11644473600) * 10000000);
    return .{
        .dwLowDateTime = @intCast(intervals & 0xffffffff),
        .dwHighDateTime = @intCast(intervals >> 32),
    };
}

fn fileTimeToUnixSeconds(file_time: *const FILETIME) i64 {
    const intervals = (@as(u64, file_time.dwHighDateTime) << 32) | file_time.dwLowDateTime;
    return @as(i64, @intCast(intervals / 10000000)) - 11644473600;
}

export fn GetFileInformationByHandle(file: HANDLE, file_information: ?*BY_HANDLE_FILE_INFORMATION) callconv(.c) BOOL {
    const info = file_information orelse {
        last_error = 87;
        return 0;
    };
    const handle = asHandle(file) orelse {
        last_error = 6;
        return 0;
    };
    var st: Stat = undefined;
    if (fstat(handle.fd, &st) != 0) {
        setLastErrorFromErrno();
        return 0;
    }
    const size: u64 = @intCast(st.st_size);
    const ft = unixSecondsToFileTime(@intCast(st.st_mtim.tv_sec));
    info.* = .{
        .dwFileAttributes = 0,
        .ftCreationTime = ft,
        .ftLastAccessTime = unixSecondsToFileTime(@intCast(st.st_atim.tv_sec)),
        .ftLastWriteTime = ft,
        .dwVolumeSerialNumber = 0,
        .nFileSizeHigh = @intCast(size >> 32),
        .nFileSizeLow = @intCast(size & 0xffffffff),
        .nNumberOfLinks = @intCast(st.st_nlink),
        .nFileIndexHigh = 0,
        .nFileIndexLow = @intCast(st.st_ino & 0xffffffff),
    };
    clearLastError();
    return 1;
}

export fn FileTimeToDosDateTime(file_time: *const FILETIME, fat_date: ?*WORD, fat_time: ?*WORD) callconv(.c) BOOL {
    const unix_seconds = fileTimeToUnixSeconds(file_time);
    if (unix_seconds < 315532800) {
        last_error = 87;
        return 0;
    }
    const epoch_seconds = std.time.epoch.EpochSeconds{ .secs = @intCast(unix_seconds) };
    const epoch_day = epoch_seconds.getEpochDay();
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const day_seconds = epoch_seconds.getDaySeconds();
    const year = if (year_day.year < 1980) 1980 else year_day.year;
    if (fat_date) |date| {
        date.* = (@as(WORD, @intCast(year - 1980)) << 9) |
            (@as(WORD, month_day.month.numeric()) << 5) |
            @as(WORD, @intCast(month_day.day_index + 1));
    }
    if (fat_time) |time| {
        time.* = (@as(WORD, day_seconds.getHoursIntoDay()) << 11) |
            (@as(WORD, day_seconds.getMinutesIntoHour()) << 5) |
            @as(WORD, day_seconds.getSecondsIntoMinute() / 2);
    }
    clearLastError();
    return 1;
}

export fn DosDateTimeToFileTime(fat_date: WORD, fat_time: WORD, file_time: ?*FILETIME) callconv(.c) BOOL {
    const out = file_time orelse {
        last_error = 87;
        return 0;
    };
    const year: u16 = 1980 + @as(u16, @intCast((fat_date >> 9) & 0x7f));
    const month: u8 = @intCast((fat_date >> 5) & 0x0f);
    const day: u8 = @intCast(fat_date & 0x1f);
    const hour: u8 = @intCast((fat_time >> 11) & 0x1f);
    const minute: u8 = @intCast((fat_time >> 5) & 0x3f);
    const second: u8 = @intCast((fat_time & 0x1f) * 2);

    var days: u64 = 0;
    var y: u16 = 1970;
    while (y < year) : (y += 1) {
        days += std.time.epoch.getDaysInYear(y);
    }
    var m: u8 = 1;
    while (m < month) : (m += 1) {
        days += std.time.epoch.getDaysInMonth(year, @enumFromInt(m));
    }
    days += day - 1;
    const seconds: i64 = @intCast(days * 86400 + @as(u64, hour) * 3600 + @as(u64, minute) * 60 + @as(u64, second));
    out.* = unixSecondsToFileTime(seconds);
    clearLastError();
    return 1;
}

export fn SetFileTime(file: HANDLE, creation_time: ?*const FILETIME, last_access_time: ?*const FILETIME, last_write_time: ?*const FILETIME) callconv(.c) BOOL {
    _ = creation_time;
    const handle = asHandle(file) orelse {
        last_error = 6;
        return 0;
    };

    var st: Stat = undefined;
    if (fstat(handle.fd, &st) != 0) {
        setLastErrorFromErrno();
        return 0;
    }

    var times = utimbuf{
        .actime = @intCast(st.st_atim.tv_sec),
        .modtime = @intCast(st.st_mtim.tv_sec),
    };
    if (last_access_time) |access| {
        times.actime = @intCast(fileTimeToUnixSeconds(access));
    }
    if (last_write_time) |write_time_ft| {
        times.modtime = @intCast(fileTimeToUnixSeconds(write_time_ft));
    }

    // Linux has no futime in POSIX libc; update through /proc/self/fd/<fd>.
    var path_buf: [64]u8 = undefined;
    const fd_path = std.fmt.bufPrintZ(&path_buf, "/proc/self/fd/{d}", .{handle.fd}) catch {
        last_error = 206;
        return 0;
    };
    if (utime(fd_path.ptr, &times) != 0) {
        setLastErrorFromErrno();
        return 0;
    }
    clearLastError();
    return 1;
}
