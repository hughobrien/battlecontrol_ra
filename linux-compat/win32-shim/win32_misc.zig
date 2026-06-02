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
const PM_NOREMOVE: UINT = 0x0000;
const PM_REMOVE: UINT = 0x0001;
const SM_CXSCREEN: c_int = 0;
const SM_CYSCREEN: c_int = 1;
const TIME_PERIODIC: UINT = 0x0001;
const DD_OK: HRESULT = 0;
const E_NOTIMPL: HRESULT = @as(i32, @bitCast(@as(u32, 0x80004001)));
const DDERR_GENERIC: HRESULT = @as(i32, @bitCast(@as(u32, 0x80004005)));
const DDERR_INVALIDPARAMS: HRESULT = @as(i32, @bitCast(@as(u32, 0x80070057)));
const DDERR_OUTOFMEMORY: HRESULT = @as(i32, @bitCast(@as(u32, 0x8007000e)));

const DDSD_CAPS: DWORD = 0x00000001;
const DDSD_HEIGHT: DWORD = 0x00000002;
const DDSD_WIDTH: DWORD = 0x00000004;
const DDSD_PITCH: DWORD = 0x00000008;
const DDSD_LPSURFACE: DWORD = 0x00000800;
const DDSCAPS_PRIMARYSURFACE: DWORD = 0x00000200;
const DDSCAPS_OFFSCREENPLAIN: DWORD = 0x00000040;
const DDSCAPS_SYSTEMMEMORY: DWORD = 0x00000800;
const DDBLT_COLORFILL: DWORD = 0x00000400;
const DDCAPS_BLT: DWORD = 0x00000040;
const DDCAPS_BLTCOLORFILL: DWORD = 0x04000000;
const MESSAGE_QUEUE_CAPACITY: usize = 256;

const DdeString = extern struct {
    next: ?*DdeString,
    text: [1]u8,
};

const PALETTEENTRY = extern struct {
    peRed: BYTE,
    peGreen: BYTE,
    peBlue: BYTE,
    peFlags: BYTE,
};

const DDSCAPS = extern struct {
    dwCaps: DWORD,
};

const DDCOLORKEY = extern struct {
    dwColorSpaceLowValue: DWORD,
    dwColorSpaceHighValue: DWORD,
};

const DDPIXELFORMAT = extern struct {
    dwSize: DWORD,
    dwFlags: DWORD,
    dwFourCC: DWORD,
    dwRGBBitCount: DWORD,
    dwRBitMask: DWORD,
    dwGBitMask: DWORD,
    dwBBitMask: DWORD,
    dwRGBAlphaBitMask: DWORD,
};

const DDCAPS = extern struct {
    dwSize: DWORD,
    dwCaps: DWORD,
    dwCaps2: DWORD,
    dwCKeyCaps: DWORD,
    dwFXCaps: DWORD,
    dwFXAlphaCaps: DWORD,
    dwPalCaps: DWORD,
    dwSVCaps: DWORD,
    dwAlphaBltConstBitDepths: DWORD,
    dwAlphaBltPixelBitDepths: DWORD,
    dwAlphaBltSurfaceBitDepths: DWORD,
    dwAlphaOverlayConstBitDepths: DWORD,
    dwAlphaOverlayPixelBitDepths: DWORD,
    dwAlphaOverlaySurfaceBitDepths: DWORD,
    dwZBufferBitDepths: DWORD,
    dwVidMemTotal: DWORD,
    dwVidMemFree: DWORD,
    dwMaxVisibleOverlays: DWORD,
    dwCurrVisibleOverlays: DWORD,
    dwNumFourCCCodes: DWORD,
    dwAlignBoundarySrc: DWORD,
    dwAlignSizeSrc: DWORD,
    dwAlignBoundaryDest: DWORD,
    dwAlignSizeDest: DWORD,
    dwAlignStrideAlign: DWORD,
    dwRops: [8]DWORD,
    ddsCaps: DDSCAPS,
    dwMinOverlayStretch: DWORD,
    dwMaxOverlayStretch: DWORD,
    dwMinLiveVideoStretch: DWORD,
    dwMaxLiveVideoStretch: DWORD,
    dwMinHwCodecStretch: DWORD,
    dwMaxHwCodecStretch: DWORD,
    dwReserved1: DWORD,
    dwReserved2: DWORD,
    dwReserved3: DWORD,
    dwSVBCaps: DWORD,
    dwSVBCKeyCaps: DWORD,
    dwSVBFXCaps: DWORD,
    dwSVBRops: [8]DWORD,
    dwVSBCaps: DWORD,
    dwVSBCKeyCaps: DWORD,
    dwVSBFXCaps: DWORD,
    dwVSBRops: [8]DWORD,
    dwSSBCaps: DWORD,
    dwSSBCKeyCaps: DWORD,
    dwSSBFXCaps: DWORD,
    dwSSBRops: [8]DWORD,
    dwReserved4: DWORD,
    dwReserved5: DWORD,
    dwReserved6: DWORD,
};

const DDSURFACEDESC = extern struct {
    dwSize: DWORD,
    dwFlags: DWORD,
    dwHeight: DWORD,
    dwWidth: DWORD,
    lPitch: i32,
    dwBackBufferCount: DWORD,
    dwRefreshRate: DWORD,
    dwAlphaBitDepth: DWORD,
    dwReserved: DWORD,
    lpSurface: ?*anyopaque,
    ddckCKDestOverlay: DDCOLORKEY,
    ddckCKDestBlt: DDCOLORKEY,
    ddckCKSrcOverlay: DDCOLORKEY,
    ddckCKSrcBlt: DDCOLORKEY,
    ddpfPixelFormat: DDPIXELFORMAT,
    ddsCaps: DDSCAPS,
};

const DDBLTFX = extern struct {
    dwSize: DWORD,
    dwDDFX: DWORD,
    dwROP: DWORD,
    dwDDROP: DWORD,
    dwRotationAngle: DWORD,
    dwZBufferOpCode: DWORD,
    dwZBufferLow: DWORD,
    dwZBufferHigh: DWORD,
    dwZBufferBaseDest: DWORD,
    dwZDestConstBitDepth: DWORD,
    dwZDestConst: usize,
    dwZSrcConstBitDepth: DWORD,
    dwZSrcConst: usize,
    dwAlphaEdgeBlendBitDepth: DWORD,
    dwAlphaEdgeBlend: DWORD,
    dwReserved: DWORD,
    dwAlphaDestConstBitDepth: DWORD,
    dwAlphaDestConst: usize,
    dwAlphaSrcConstBitDepth: DWORD,
    dwAlphaSrcConst: usize,
    dwFillColor: usize,
    ddckDestColorkey: DDCOLORKEY,
    ddckSrcColorkey: DDCOLORKEY,
};

const DirectDrawVTable = extern struct {
    QueryInterface: *const fn (*DirectDraw, ?*const anyopaque, ?*?*anyopaque) callconv(.c) HRESULT,
    AddRef: *const fn (*DirectDraw) callconv(.c) c_ulong,
    Release: *const fn (*DirectDraw) callconv(.c) c_ulong,
    Compact: *const fn (*DirectDraw) callconv(.c) HRESULT,
    CreateClipper: *const fn (*DirectDraw, DWORD, ?*?*anyopaque, ?*anyopaque) callconv(.c) HRESULT,
    CreatePalette: *const fn (*DirectDraw, DWORD, ?[*]const PALETTEENTRY, ?*?*Palette, ?*anyopaque) callconv(.c) HRESULT,
    CreateSurface: *const fn (*DirectDraw, ?*DDSURFACEDESC, ?*?*Surface, ?*anyopaque) callconv(.c) HRESULT,
    DuplicateSurface: *const fn (*DirectDraw, ?*Surface, ?*?*Surface) callconv(.c) HRESULT,
    EnumDisplayModes: *const fn (*DirectDraw, DWORD, ?*DDSURFACEDESC, ?*anyopaque, ?*anyopaque) callconv(.c) HRESULT,
    EnumSurfaces: *const fn (*DirectDraw, DWORD, ?*DDSURFACEDESC, ?*anyopaque, ?*anyopaque) callconv(.c) HRESULT,
    FlipToGDISurface: *const fn (*DirectDraw) callconv(.c) HRESULT,
    GetCaps: *const fn (*DirectDraw, ?*DDCAPS, ?*DDCAPS) callconv(.c) HRESULT,
    GetDisplayMode: *const fn (*DirectDraw, ?*DDSURFACEDESC) callconv(.c) HRESULT,
    GetFourCCCodes: *const fn (*DirectDraw, ?*DWORD, ?*DWORD) callconv(.c) HRESULT,
    GetGDISurface: *const fn (*DirectDraw, ?*?*Surface) callconv(.c) HRESULT,
    GetMonitorFrequency: *const fn (*DirectDraw, ?*DWORD) callconv(.c) HRESULT,
    GetScanLine: *const fn (*DirectDraw, ?*DWORD) callconv(.c) HRESULT,
    GetVerticalBlankStatus: *const fn (*DirectDraw, ?*BOOL) callconv(.c) HRESULT,
    Initialize: *const fn (*DirectDraw, ?*const anyopaque) callconv(.c) HRESULT,
    RestoreDisplayMode: *const fn (*DirectDraw) callconv(.c) HRESULT,
    SetCooperativeLevel: *const fn (*DirectDraw, HWND, DWORD) callconv(.c) HRESULT,
    SetDisplayMode: *const fn (*DirectDraw, DWORD, DWORD, DWORD) callconv(.c) HRESULT,
    WaitForVerticalBlank: *const fn (*DirectDraw, DWORD, HANDLE) callconv(.c) HRESULT,
};

const PaletteVTable = extern struct {
    QueryInterface: *const fn (*Palette, ?*const anyopaque, ?*?*anyopaque) callconv(.c) HRESULT,
    AddRef: *const fn (*Palette) callconv(.c) c_ulong,
    Release: *const fn (*Palette) callconv(.c) c_ulong,
    GetCaps: *const fn (*Palette, ?*DWORD) callconv(.c) HRESULT,
    GetEntries: *const fn (*Palette, DWORD, DWORD, DWORD, ?[*]PALETTEENTRY) callconv(.c) HRESULT,
    Initialize: *const fn (*Palette, ?*DirectDraw, DWORD, ?[*]const PALETTEENTRY) callconv(.c) HRESULT,
    SetEntries: *const fn (*Palette, DWORD, DWORD, DWORD, ?[*]const PALETTEENTRY) callconv(.c) HRESULT,
};

const SurfaceVTable = extern struct {
    QueryInterface: *const fn (*Surface, ?*const anyopaque, ?*?*anyopaque) callconv(.c) HRESULT,
    AddRef: *const fn (*Surface) callconv(.c) c_ulong,
    Release: *const fn (*Surface) callconv(.c) c_ulong,
    AddAttachedSurface: *const fn (*Surface, ?*Surface) callconv(.c) HRESULT,
    AddOverlayDirtyRect: *const fn (*Surface, ?*RECT) callconv(.c) HRESULT,
    Blt: *const fn (*Surface, ?*RECT, ?*Surface, ?*RECT, DWORD, ?*DDBLTFX) callconv(.c) HRESULT,
    BltBatch: *const fn (*Surface, ?*anyopaque, DWORD, DWORD) callconv(.c) HRESULT,
    BltFast: *const fn (*Surface, DWORD, DWORD, ?*Surface, ?*RECT, DWORD) callconv(.c) HRESULT,
    DeleteAttachedSurface: *const fn (*Surface, DWORD, ?*Surface) callconv(.c) HRESULT,
    EnumAttachedSurfaces: *const fn (*Surface, ?*anyopaque, ?*anyopaque) callconv(.c) HRESULT,
    EnumOverlayZOrders: *const fn (*Surface, DWORD, ?*anyopaque, ?*anyopaque) callconv(.c) HRESULT,
    Flip: *const fn (*Surface, ?*Surface, DWORD) callconv(.c) HRESULT,
    GetAttachedSurface: *const fn (*Surface, ?*DDSCAPS, ?*?*Surface) callconv(.c) HRESULT,
    GetBltStatus: *const fn (*Surface, DWORD) callconv(.c) HRESULT,
    GetCaps: *const fn (*Surface, ?*DDSCAPS) callconv(.c) HRESULT,
    GetClipper: *const fn (*Surface, ?*?*anyopaque) callconv(.c) HRESULT,
    GetColorKey: *const fn (*Surface, DWORD, ?*DDCOLORKEY) callconv(.c) HRESULT,
    GetDC: *const fn (*Surface, ?*?*anyopaque) callconv(.c) HRESULT,
    GetFlipStatus: *const fn (*Surface, DWORD) callconv(.c) HRESULT,
    GetOverlayPosition: *const fn (*Surface, ?*LONG, ?*LONG) callconv(.c) HRESULT,
    GetPalette: *const fn (*Surface, ?*?*Palette) callconv(.c) HRESULT,
    GetPixelFormat: *const fn (*Surface, ?*DDPIXELFORMAT) callconv(.c) HRESULT,
    GetSurfaceDesc: *const fn (*Surface, ?*DDSURFACEDESC) callconv(.c) HRESULT,
    Initialize: *const fn (*Surface, ?*DirectDraw, ?*DDSURFACEDESC) callconv(.c) HRESULT,
    IsLost: *const fn (*Surface) callconv(.c) HRESULT,
    Lock: *const fn (*Surface, ?*RECT, ?*DDSURFACEDESC, DWORD, HANDLE) callconv(.c) HRESULT,
    ReleaseDC: *const fn (*Surface, ?*anyopaque) callconv(.c) HRESULT,
    Restore: *const fn (*Surface) callconv(.c) HRESULT,
    SetClipper: *const fn (*Surface, ?*anyopaque) callconv(.c) HRESULT,
    SetColorKey: *const fn (*Surface, DWORD, ?*DDCOLORKEY) callconv(.c) HRESULT,
    SetOverlayPosition: *const fn (*Surface, LONG, LONG) callconv(.c) HRESULT,
    SetPalette: *const fn (*Surface, ?*Palette) callconv(.c) HRESULT,
    Unlock: *const fn (*Surface, ?*anyopaque) callconv(.c) HRESULT,
    UpdateOverlay: *const fn (*Surface, ?*RECT, ?*Surface, ?*RECT, DWORD, ?*anyopaque) callconv(.c) HRESULT,
    UpdateOverlayDisplay: *const fn (*Surface, DWORD) callconv(.c) HRESULT,
    UpdateOverlayZOrder: *const fn (*Surface, DWORD, ?*Surface) callconv(.c) HRESULT,
};

const DirectDraw = extern struct {
    vtable: *const DirectDrawVTable,
    ref_count: c_ulong,
    width: DWORD,
    height: DWORD,
    bits_per_pixel: DWORD,
};

const Palette = extern struct {
    vtable: *const PaletteVTable,
    ref_count: c_ulong,
    entries: [256]PALETTEENTRY,
};

const Surface = extern struct {
    vtable: *const SurfaceVTable,
    ref_count: c_ulong,
    width: DWORD,
    height: DWORD,
    pitch: i32,
    caps: DWORD,
    buffer: ?[*]u8,
    buffer_len: usize,
    attached: ?*Surface,
    palette: ?*Palette,
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
var message_mutex: std.atomic.Mutex = .unlocked;
var message_queue: [MESSAGE_QUEUE_CAPACITY]MSG = undefined;
var message_count: usize = 0;
var registered_window_proc: WNDPROC = null;
var main_window_handle: HWND = @ptrFromInt(1);
var injected_key_sequence_loaded = false;

export var CPUType: u8 = 0;

export fn DirectDrawCreate(guid: ?*const anyopaque, direct_draw: ?*?*anyopaque, outer: ?*anyopaque) callconv(.c) HRESULT {
    _ = guid;
    _ = outer;
    const out = direct_draw orelse return DDERR_INVALIDPARAMS;
    const mem = std.c.malloc(@sizeOf(DirectDraw)) orelse {
        out.* = null;
        return DDERR_OUTOFMEMORY;
    };
    const direct_draw_object: *DirectDraw = @ptrCast(@alignCast(mem));
    direct_draw_object.* = .{
        .vtable = &direct_draw_vtable,
        .ref_count = 1,
        .width = 640,
        .height = 400,
        .bits_per_pixel = 8,
    };
    out.* = @ptrCast(direct_draw_object);
    return DD_OK;
}

fn fillCaps(caps: *DDCAPS) void {
    const size = caps.dwSize;
    @memset(std.mem.asBytes(caps), 0);
    caps.dwSize = size;
    caps.dwCaps = DDCAPS_BLT | DDCAPS_BLTCOLORFILL;
    caps.dwSVBCaps = DDCAPS_BLT;
    caps.dwVSBCaps = DDCAPS_BLT;
    caps.dwSSBCaps = DDCAPS_BLT;
    caps.dwVidMemTotal = 16 * 1024 * 1024;
    caps.dwVidMemFree = 16 * 1024 * 1024;
}

fn directDrawQueryInterface(self: *DirectDraw, _: ?*const anyopaque, out: ?*?*anyopaque) callconv(.c) HRESULT {
    if (out) |object| object.* = @ptrCast(self);
    _ = directDrawAddRef(self);
    return DD_OK;
}

fn directDrawAddRef(self: *DirectDraw) callconv(.c) c_ulong {
    self.ref_count += 1;
    return self.ref_count;
}

fn directDrawRelease(self: *DirectDraw) callconv(.c) c_ulong {
    if (self.ref_count > 0) self.ref_count -= 1;
    const remaining = self.ref_count;
    if (remaining == 0) std.c.free(self);
    return remaining;
}

fn directDrawCompact(_: *DirectDraw) callconv(.c) HRESULT {
    return DD_OK;
}

fn directDrawCreateClipper(_: *DirectDraw, _: DWORD, out: ?*?*anyopaque, _: ?*anyopaque) callconv(.c) HRESULT {
    if (out) |clipper| clipper.* = null;
    return E_NOTIMPL;
}

fn directDrawCreatePalette(_: *DirectDraw, _: DWORD, entries: ?[*]const PALETTEENTRY, out: ?*?*Palette, _: ?*anyopaque) callconv(.c) HRESULT {
    const palette_out = out orelse return DDERR_INVALIDPARAMS;
    const mem = std.c.malloc(@sizeOf(Palette)) orelse {
        palette_out.* = null;
        return DDERR_OUTOFMEMORY;
    };
    const palette: *Palette = @ptrCast(@alignCast(mem));
    palette.* = .{
        .vtable = &palette_vtable,
        .ref_count = 1,
        .entries = [_]PALETTEENTRY{.{ .peRed = 0, .peGreen = 0, .peBlue = 0, .peFlags = 0 }} ** 256,
    };
    if (entries) |source| {
        @memcpy(palette.entries[0..], source[0..256]);
    }
    palette_out.* = palette;
    return DD_OK;
}

fn directDrawCreateSurface(self: *DirectDraw, desc: ?*DDSURFACEDESC, out: ?*?*Surface, _: ?*anyopaque) callconv(.c) HRESULT {
    const surface_out = out orelse return DDERR_INVALIDPARAMS;
    const requested = desc orelse return DDERR_INVALIDPARAMS;
    const caps = requested.ddsCaps.dwCaps;
    const width = if ((caps & DDSCAPS_PRIMARYSURFACE) != 0) self.width else requested.dwWidth;
    const height = if ((caps & DDSCAPS_PRIMARYSURFACE) != 0) self.height else requested.dwHeight;
    if (width == 0 or height == 0) {
        surface_out.* = null;
        return DDERR_INVALIDPARAMS;
    }

    const surface_mem = std.c.malloc(@sizeOf(Surface)) orelse {
        surface_out.* = null;
        return DDERR_OUTOFMEMORY;
    };
    const bytes: usize = @as(usize, width) * @as(usize, height);
    const buffer_mem = std.c.malloc(bytes) orelse {
        std.c.free(surface_mem);
        surface_out.* = null;
        return DDERR_OUTOFMEMORY;
    };
    const buffer: [*]u8 = @ptrCast(buffer_mem);
    @memset(buffer[0..bytes], 0);

    const surface: *Surface = @ptrCast(@alignCast(surface_mem));
    surface.* = .{
        .vtable = &surface_vtable,
        .ref_count = 1,
        .width = width,
        .height = height,
        .pitch = @intCast(width),
        .caps = caps,
        .buffer = buffer,
        .buffer_len = bytes,
        .attached = null,
        .palette = null,
    };
    surface_out.* = surface;
    return DD_OK;
}

fn directDrawDuplicateSurface(_: *DirectDraw, _: ?*Surface, out: ?*?*Surface) callconv(.c) HRESULT {
    if (out) |surface| surface.* = null;
    return E_NOTIMPL;
}

fn directDrawEnumDisplayModes(_: *DirectDraw, _: DWORD, _: ?*DDSURFACEDESC, _: ?*anyopaque, _: ?*anyopaque) callconv(.c) HRESULT {
    return E_NOTIMPL;
}

fn directDrawEnumSurfaces(_: *DirectDraw, _: DWORD, _: ?*DDSURFACEDESC, _: ?*anyopaque, _: ?*anyopaque) callconv(.c) HRESULT {
    return E_NOTIMPL;
}

fn directDrawFlipToGDISurface(_: *DirectDraw) callconv(.c) HRESULT {
    return DD_OK;
}

fn directDrawGetCaps(_: *DirectDraw, hardware: ?*DDCAPS, emulation: ?*DDCAPS) callconv(.c) HRESULT {
    if (hardware) |caps| fillCaps(caps);
    if (emulation) |caps| fillCaps(caps);
    return DD_OK;
}

fn directDrawGetDisplayMode(self: *DirectDraw, desc: ?*DDSURFACEDESC) callconv(.c) HRESULT {
    const out = desc orelse return DDERR_INVALIDPARAMS;
    const size = out.dwSize;
    @memset(std.mem.asBytes(out), 0);
    out.dwSize = size;
    out.dwFlags = DDSD_WIDTH | DDSD_HEIGHT | DDSD_PITCH;
    out.dwWidth = self.width;
    out.dwHeight = self.height;
    out.lPitch = @intCast(self.width);
    return DD_OK;
}

fn directDrawGetFourCCCodes(_: *DirectDraw, count: ?*DWORD, codes: ?*DWORD) callconv(.c) HRESULT {
    if (count) |value| value.* = 0;
    _ = codes;
    return DD_OK;
}

fn directDrawGetGDISurface(_: *DirectDraw, out: ?*?*Surface) callconv(.c) HRESULT {
    if (out) |surface| surface.* = null;
    return E_NOTIMPL;
}

fn directDrawGetMonitorFrequency(_: *DirectDraw, frequency: ?*DWORD) callconv(.c) HRESULT {
    if (frequency) |value| value.* = 60;
    return DD_OK;
}

fn directDrawGetScanLine(_: *DirectDraw, line: ?*DWORD) callconv(.c) HRESULT {
    if (line) |value| value.* = 0;
    return DD_OK;
}

fn directDrawGetVerticalBlankStatus(_: *DirectDraw, status: ?*BOOL) callconv(.c) HRESULT {
    if (status) |value| value.* = 1;
    return DD_OK;
}

fn directDrawInitialize(_: *DirectDraw, _: ?*const anyopaque) callconv(.c) HRESULT {
    return DD_OK;
}

fn directDrawRestoreDisplayMode(_: *DirectDraw) callconv(.c) HRESULT {
    return DD_OK;
}

fn directDrawSetCooperativeLevel(_: *DirectDraw, _: HWND, _: DWORD) callconv(.c) HRESULT {
    return DD_OK;
}

fn directDrawSetDisplayMode(self: *DirectDraw, width: DWORD, height: DWORD, bits_per_pixel: DWORD) callconv(.c) HRESULT {
    self.width = width;
    self.height = height;
    self.bits_per_pixel = bits_per_pixel;
    return DD_OK;
}

fn directDrawWaitForVerticalBlank(_: *DirectDraw, _: DWORD, _: HANDLE) callconv(.c) HRESULT {
    return E_NOTIMPL;
}

fn paletteQueryInterface(self: *Palette, _: ?*const anyopaque, out: ?*?*anyopaque) callconv(.c) HRESULT {
    if (out) |object| object.* = @ptrCast(self);
    _ = paletteAddRef(self);
    return DD_OK;
}

fn paletteAddRef(self: *Palette) callconv(.c) c_ulong {
    self.ref_count += 1;
    return self.ref_count;
}

fn paletteRelease(self: *Palette) callconv(.c) c_ulong {
    if (self.ref_count > 0) self.ref_count -= 1;
    const remaining = self.ref_count;
    if (remaining == 0) std.c.free(self);
    return remaining;
}

fn paletteGetCaps(_: *Palette, caps: ?*DWORD) callconv(.c) HRESULT {
    if (caps) |value| value.* = 0;
    return DD_OK;
}

fn paletteGetEntries(self: *Palette, _: DWORD, start: DWORD, count: DWORD, entries: ?[*]PALETTEENTRY) callconv(.c) HRESULT {
    const out = entries orelse return DDERR_INVALIDPARAMS;
    const begin: usize = start;
    const len: usize = count;
    if (begin + len > self.entries.len) return DDERR_INVALIDPARAMS;
    @memcpy(out[0..len], self.entries[begin .. begin + len]);
    return DD_OK;
}

fn paletteInitialize(self: *Palette, _: ?*DirectDraw, _: DWORD, entries: ?[*]const PALETTEENTRY) callconv(.c) HRESULT {
    if (entries) |source| @memcpy(self.entries[0..], source[0..256]);
    return DD_OK;
}

fn paletteSetEntries(self: *Palette, _: DWORD, start: DWORD, count: DWORD, entries: ?[*]const PALETTEENTRY) callconv(.c) HRESULT {
    const source = entries orelse return DDERR_INVALIDPARAMS;
    const begin: usize = start;
    const len: usize = count;
    if (begin + len > self.entries.len) return DDERR_INVALIDPARAMS;
    @memcpy(self.entries[begin .. begin + len], source[0..len]);
    return DD_OK;
}

fn surfaceQueryInterface(self: *Surface, _: ?*const anyopaque, out: ?*?*anyopaque) callconv(.c) HRESULT {
    if (out) |object| object.* = @ptrCast(self);
    _ = surfaceAddRef(self);
    return DD_OK;
}

fn surfaceAddRef(self: *Surface) callconv(.c) c_ulong {
    self.ref_count += 1;
    return self.ref_count;
}

fn surfaceRelease(self: *Surface) callconv(.c) c_ulong {
    if (self.ref_count > 0) self.ref_count -= 1;
    const remaining = self.ref_count;
    if (remaining == 0) {
        if (self.buffer) |buffer| std.c.free(buffer);
        std.c.free(self);
    }
    return remaining;
}

fn surfaceAddAttachedSurface(self: *Surface, attached: ?*Surface) callconv(.c) HRESULT {
    self.attached = attached;
    return DD_OK;
}

fn surfaceAddOverlayDirtyRect(_: *Surface, _: ?*RECT) callconv(.c) HRESULT {
    return E_NOTIMPL;
}

fn rectOrFull(rect: ?*RECT, width: DWORD, height: DWORD) RECT {
    return if (rect) |value| value.* else RECT{ .left = 0, .top = 0, .right = @intCast(width), .bottom = @intCast(height) };
}

fn clampRect(rect: RECT, width: DWORD, height: DWORD) RECT {
    return .{
        .left = @max(0, @min(rect.left, @as(LONG, @intCast(width)))),
        .top = @max(0, @min(rect.top, @as(LONG, @intCast(height)))),
        .right = @max(0, @min(rect.right, @as(LONG, @intCast(width)))),
        .bottom = @max(0, @min(rect.bottom, @as(LONG, @intCast(height)))),
    };
}

fn surfaceBlt(self: *Surface, dest_rect: ?*RECT, source: ?*Surface, source_rect: ?*RECT, flags: DWORD, effects: ?*DDBLTFX) callconv(.c) HRESULT {
    const dest_buffer = self.buffer orelse return DDERR_GENERIC;
    const dest = clampRect(rectOrFull(dest_rect, self.width, self.height), self.width, self.height);
    if (dest.right <= dest.left or dest.bottom <= dest.top) return DD_OK;

    if ((flags & DDBLT_COLORFILL) != 0) {
        const fill: u8 = if (effects) |fx| @truncate(fx.dwFillColor) else 0;
        var y: LONG = dest.top;
        while (y < dest.bottom) : (y += 1) {
            const row: usize = @as(usize, @intCast(y)) * @as(usize, @intCast(self.pitch));
            @memset(dest_buffer[row + @as(usize, @intCast(dest.left)) .. row + @as(usize, @intCast(dest.right))], fill);
        }
        return DD_OK;
    }

    const src = source orelse return DDERR_INVALIDPARAMS;
    const src_buffer = src.buffer orelse return DDERR_GENERIC;
    const source_area = clampRect(rectOrFull(source_rect, src.width, src.height), src.width, src.height);
    const copy_width: usize = @intCast(@min(dest.right - dest.left, source_area.right - source_area.left));
    const copy_height: usize = @intCast(@min(dest.bottom - dest.top, source_area.bottom - source_area.top));
    var row_index: usize = 0;
    while (row_index < copy_height) : (row_index += 1) {
        const src_y: usize = @as(usize, @intCast(source_area.top)) + row_index;
        const dest_y: usize = @as(usize, @intCast(dest.top)) + row_index;
        const src_start = src_y * @as(usize, @intCast(src.pitch)) + @as(usize, @intCast(source_area.left));
        const dest_start = dest_y * @as(usize, @intCast(self.pitch)) + @as(usize, @intCast(dest.left));
        std.mem.copyForwards(u8, dest_buffer[dest_start .. dest_start + copy_width], src_buffer[src_start .. src_start + copy_width]);
    }
    return DD_OK;
}

fn surfaceBltBatch(_: *Surface, _: ?*anyopaque, _: DWORD, _: DWORD) callconv(.c) HRESULT {
    return E_NOTIMPL;
}

fn surfaceBltFast(self: *Surface, x: DWORD, y: DWORD, source: ?*Surface, source_rect: ?*RECT, flags: DWORD) callconv(.c) HRESULT {
    const src = source orelse return DDERR_INVALIDPARAMS;
    const area = rectOrFull(source_rect, src.width, src.height);
    var dest = RECT{
        .left = @intCast(x),
        .top = @intCast(y),
        .right = @intCast(x + @as(DWORD, @intCast(area.right - area.left))),
        .bottom = @intCast(y + @as(DWORD, @intCast(area.bottom - area.top))),
    };
    return surfaceBlt(self, &dest, src, source_rect, flags, null);
}

fn surfaceDeleteAttachedSurface(self: *Surface, _: DWORD, surface: ?*Surface) callconv(.c) HRESULT {
    if (self.attached == surface) self.attached = null;
    return DD_OK;
}

fn surfaceEnumAttachedSurfaces(_: *Surface, _: ?*anyopaque, _: ?*anyopaque) callconv(.c) HRESULT {
    return E_NOTIMPL;
}

fn surfaceEnumOverlayZOrders(_: *Surface, _: DWORD, _: ?*anyopaque, _: ?*anyopaque) callconv(.c) HRESULT {
    return E_NOTIMPL;
}

fn surfaceFlip(_: *Surface, _: ?*Surface, _: DWORD) callconv(.c) HRESULT {
    return DD_OK;
}

fn surfaceGetAttachedSurface(self: *Surface, _: ?*DDSCAPS, out: ?*?*Surface) callconv(.c) HRESULT {
    const surface_out = out orelse return DDERR_INVALIDPARAMS;
    surface_out.* = self.attached;
    return if (self.attached != null) DD_OK else E_NOTIMPL;
}

fn surfaceGetBltStatus(_: *Surface, _: DWORD) callconv(.c) HRESULT {
    return DD_OK;
}

fn surfaceGetCaps(self: *Surface, caps: ?*DDSCAPS) callconv(.c) HRESULT {
    const out = caps orelse return DDERR_INVALIDPARAMS;
    out.dwCaps = self.caps;
    return DD_OK;
}

fn surfaceGetClipper(_: *Surface, out: ?*?*anyopaque) callconv(.c) HRESULT {
    if (out) |clipper| clipper.* = null;
    return E_NOTIMPL;
}

fn surfaceGetColorKey(_: *Surface, _: DWORD, key: ?*DDCOLORKEY) callconv(.c) HRESULT {
    if (key) |value| value.* = .{ .dwColorSpaceLowValue = 0, .dwColorSpaceHighValue = 0 };
    return E_NOTIMPL;
}

fn surfaceGetDC(_: *Surface, dc: ?*?*anyopaque) callconv(.c) HRESULT {
    if (dc) |out| out.* = null;
    return E_NOTIMPL;
}

fn surfaceGetFlipStatus(_: *Surface, _: DWORD) callconv(.c) HRESULT {
    return DD_OK;
}

fn surfaceGetOverlayPosition(_: *Surface, x: ?*LONG, y: ?*LONG) callconv(.c) HRESULT {
    if (x) |value| value.* = 0;
    if (y) |value| value.* = 0;
    return DD_OK;
}

fn surfaceGetPalette(self: *Surface, palette: ?*?*Palette) callconv(.c) HRESULT {
    const out = palette orelse return DDERR_INVALIDPARAMS;
    out.* = self.palette;
    return if (self.palette != null) DD_OK else E_NOTIMPL;
}

fn surfaceGetPixelFormat(_: *Surface, format: ?*DDPIXELFORMAT) callconv(.c) HRESULT {
    const out = format orelse return DDERR_INVALIDPARAMS;
    @memset(std.mem.asBytes(out), 0);
    out.dwSize = @sizeOf(DDPIXELFORMAT);
    out.dwRGBBitCount = 8;
    return DD_OK;
}

fn fillSurfaceDesc(self: *Surface, desc: *DDSURFACEDESC) void {
    const size = desc.dwSize;
    @memset(std.mem.asBytes(desc), 0);
    desc.dwSize = size;
    desc.dwFlags = DDSD_CAPS | DDSD_WIDTH | DDSD_HEIGHT | DDSD_PITCH | DDSD_LPSURFACE;
    desc.dwWidth = self.width;
    desc.dwHeight = self.height;
    desc.lPitch = self.pitch;
    desc.lpSurface = if (self.buffer) |buffer| @ptrCast(buffer) else null;
    desc.ddsCaps.dwCaps = self.caps;
}

fn surfaceGetSurfaceDesc(self: *Surface, desc: ?*DDSURFACEDESC) callconv(.c) HRESULT {
    const out = desc orelse return DDERR_INVALIDPARAMS;
    fillSurfaceDesc(self, out);
    return DD_OK;
}

fn surfaceInitialize(_: *Surface, _: ?*DirectDraw, _: ?*DDSURFACEDESC) callconv(.c) HRESULT {
    return DD_OK;
}

fn surfaceIsLost(_: *Surface) callconv(.c) HRESULT {
    return DD_OK;
}

fn surfaceLock(self: *Surface, _: ?*RECT, desc: ?*DDSURFACEDESC, _: DWORD, _: HANDLE) callconv(.c) HRESULT {
    const out = desc orelse return DDERR_INVALIDPARAMS;
    fillSurfaceDesc(self, out);
    return DD_OK;
}

fn surfaceReleaseDC(_: *Surface, _: ?*anyopaque) callconv(.c) HRESULT {
    return E_NOTIMPL;
}

fn surfaceRestore(_: *Surface) callconv(.c) HRESULT {
    return DD_OK;
}

fn surfaceSetClipper(_: *Surface, _: ?*anyopaque) callconv(.c) HRESULT {
    return DD_OK;
}

fn surfaceSetColorKey(_: *Surface, _: DWORD, _: ?*DDCOLORKEY) callconv(.c) HRESULT {
    return DD_OK;
}

fn surfaceSetOverlayPosition(_: *Surface, _: LONG, _: LONG) callconv(.c) HRESULT {
    return DD_OK;
}

fn surfaceSetPalette(self: *Surface, palette: ?*Palette) callconv(.c) HRESULT {
    self.palette = palette;
    return DD_OK;
}

fn surfaceUnlock(_: *Surface, _: ?*anyopaque) callconv(.c) HRESULT {
    return DD_OK;
}

fn surfaceUpdateOverlay(_: *Surface, _: ?*RECT, _: ?*Surface, _: ?*RECT, _: DWORD, _: ?*anyopaque) callconv(.c) HRESULT {
    return E_NOTIMPL;
}

fn surfaceUpdateOverlayDisplay(_: *Surface, _: DWORD) callconv(.c) HRESULT {
    return E_NOTIMPL;
}

fn surfaceUpdateOverlayZOrder(_: *Surface, _: DWORD, _: ?*Surface) callconv(.c) HRESULT {
    return E_NOTIMPL;
}

const direct_draw_vtable = DirectDrawVTable{
    .QueryInterface = directDrawQueryInterface,
    .AddRef = directDrawAddRef,
    .Release = directDrawRelease,
    .Compact = directDrawCompact,
    .CreateClipper = directDrawCreateClipper,
    .CreatePalette = directDrawCreatePalette,
    .CreateSurface = directDrawCreateSurface,
    .DuplicateSurface = directDrawDuplicateSurface,
    .EnumDisplayModes = directDrawEnumDisplayModes,
    .EnumSurfaces = directDrawEnumSurfaces,
    .FlipToGDISurface = directDrawFlipToGDISurface,
    .GetCaps = directDrawGetCaps,
    .GetDisplayMode = directDrawGetDisplayMode,
    .GetFourCCCodes = directDrawGetFourCCCodes,
    .GetGDISurface = directDrawGetGDISurface,
    .GetMonitorFrequency = directDrawGetMonitorFrequency,
    .GetScanLine = directDrawGetScanLine,
    .GetVerticalBlankStatus = directDrawGetVerticalBlankStatus,
    .Initialize = directDrawInitialize,
    .RestoreDisplayMode = directDrawRestoreDisplayMode,
    .SetCooperativeLevel = directDrawSetCooperativeLevel,
    .SetDisplayMode = directDrawSetDisplayMode,
    .WaitForVerticalBlank = directDrawWaitForVerticalBlank,
};

const palette_vtable = PaletteVTable{
    .QueryInterface = paletteQueryInterface,
    .AddRef = paletteAddRef,
    .Release = paletteRelease,
    .GetCaps = paletteGetCaps,
    .GetEntries = paletteGetEntries,
    .Initialize = paletteInitialize,
    .SetEntries = paletteSetEntries,
};

const surface_vtable = SurfaceVTable{
    .QueryInterface = surfaceQueryInterface,
    .AddRef = surfaceAddRef,
    .Release = surfaceRelease,
    .AddAttachedSurface = surfaceAddAttachedSurface,
    .AddOverlayDirtyRect = surfaceAddOverlayDirtyRect,
    .Blt = surfaceBlt,
    .BltBatch = surfaceBltBatch,
    .BltFast = surfaceBltFast,
    .DeleteAttachedSurface = surfaceDeleteAttachedSurface,
    .EnumAttachedSurfaces = surfaceEnumAttachedSurfaces,
    .EnumOverlayZOrders = surfaceEnumOverlayZOrders,
    .Flip = surfaceFlip,
    .GetAttachedSurface = surfaceGetAttachedSurface,
    .GetBltStatus = surfaceGetBltStatus,
    .GetCaps = surfaceGetCaps,
    .GetClipper = surfaceGetClipper,
    .GetColorKey = surfaceGetColorKey,
    .GetDC = surfaceGetDC,
    .GetFlipStatus = surfaceGetFlipStatus,
    .GetOverlayPosition = surfaceGetOverlayPosition,
    .GetPalette = surfaceGetPalette,
    .GetPixelFormat = surfaceGetPixelFormat,
    .GetSurfaceDesc = surfaceGetSurfaceDesc,
    .Initialize = surfaceInitialize,
    .IsLost = surfaceIsLost,
    .Lock = surfaceLock,
    .ReleaseDC = surfaceReleaseDC,
    .Restore = surfaceRestore,
    .SetClipper = surfaceSetClipper,
    .SetColorKey = surfaceSetColorKey,
    .SetOverlayPosition = surfaceSetOverlayPosition,
    .SetPalette = surfaceSetPalette,
    .Unlock = surfaceUnlock,
    .UpdateOverlay = surfaceUpdateOverlay,
    .UpdateOverlayDisplay = surfaceUpdateOverlayDisplay,
    .UpdateOverlayZOrder = surfaceUpdateOverlayZOrder,
};

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
        .pt = .{ .x = cursor_x, .y = cursor_y },
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
    injected_key_sequence_loaded = true;
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

fn loadInjectedKeySequenceOnce() void {
    if (injected_key_sequence_loaded) return;
    injected_key_sequence_loaded = true;

    const raw_sequence = getenv("BATTLECONTROL_KEY_SEQUENCE") orelse return;
    var tokens = std.mem.tokenizeAny(u8, std.mem.span(raw_sequence), ",; \t\r\n");
    while (tokens.next()) |token| {
        const virtual_key = parseVirtualKey(token) orelse continue;
        _ = enqueueMessage(makeMessage(main_window_handle, WM_KEYDOWN, virtual_key, 0));
        _ = enqueueMessage(makeMessage(main_window_handle, WM_KEYUP, virtual_key, 0));
    }
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
    loadInjectedKeySequenceOnce();
    const message = dequeueMessage(window, filter_min, filter_max, (remove_msg & PM_REMOVE) != PM_NOREMOVE) orelse return 0;
    if (msg) |out| out.* = message;
    return 1;
}

export fn GetMessage(msg: ?*MSG, window: HWND, filter_min: UINT, filter_max: UINT) callconv(.c) BOOL {
    loadInjectedKeySequenceOnce();
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

test "DirectDrawCreate returns a DirectDraw object" {
    var direct_draw: ?*anyopaque = null;

    try std.testing.expectEqual(DD_OK, DirectDrawCreate(null, &direct_draw, null));
    try std.testing.expect(direct_draw != null);
    const object: *DirectDraw = @ptrCast(@alignCast(direct_draw.?));
    try std.testing.expectEqual(@as(c_ulong, 0), object.vtable.Release(object));
}

test "DirectDraw creates an in-memory palette" {
    var direct_draw_any: ?*anyopaque = null;
    try std.testing.expectEqual(DD_OK, DirectDrawCreate(null, &direct_draw_any, null));
    const direct_draw: *DirectDraw = @ptrCast(@alignCast(direct_draw_any.?));
    defer _ = direct_draw.vtable.Release(direct_draw);

    var entries = [_]PALETTEENTRY{.{ .peRed = 1, .peGreen = 2, .peBlue = 3, .peFlags = 4 }} ** 256;
    var palette: ?*Palette = null;
    try std.testing.expectEqual(DD_OK, direct_draw.vtable.CreatePalette(direct_draw, 0, &entries, &palette, null));
    defer _ = palette.?.vtable.Release(palette.?);

    entries[0] = .{ .peRed = 10, .peGreen = 20, .peBlue = 30, .peFlags = 40 };
    try std.testing.expectEqual(DD_OK, palette.?.vtable.SetEntries(palette.?, 0, 0, 1, &entries));

    var out = [_]PALETTEENTRY{.{ .peRed = 0, .peGreen = 0, .peBlue = 0, .peFlags = 0 }} ** 1;
    try std.testing.expectEqual(DD_OK, palette.?.vtable.GetEntries(palette.?, 0, 0, 1, &out));
    try std.testing.expectEqual(entries[0], out[0]);
}

test "DirectDraw creates lockable memory-backed surfaces" {
    var direct_draw_any: ?*anyopaque = null;
    try std.testing.expectEqual(DD_OK, DirectDrawCreate(null, &direct_draw_any, null));
    const direct_draw: *DirectDraw = @ptrCast(@alignCast(direct_draw_any.?));
    defer _ = direct_draw.vtable.Release(direct_draw);

    var desc = DDSURFACEDESC{
        .dwSize = @sizeOf(DDSURFACEDESC),
        .dwFlags = DDSD_CAPS | DDSD_WIDTH | DDSD_HEIGHT,
        .dwHeight = 4,
        .dwWidth = 8,
        .lPitch = 0,
        .dwBackBufferCount = 0,
        .dwRefreshRate = 0,
        .dwAlphaBitDepth = 0,
        .dwReserved = 0,
        .lpSurface = null,
        .ddckCKDestOverlay = .{ .dwColorSpaceLowValue = 0, .dwColorSpaceHighValue = 0 },
        .ddckCKDestBlt = .{ .dwColorSpaceLowValue = 0, .dwColorSpaceHighValue = 0 },
        .ddckCKSrcOverlay = .{ .dwColorSpaceLowValue = 0, .dwColorSpaceHighValue = 0 },
        .ddckCKSrcBlt = .{ .dwColorSpaceLowValue = 0, .dwColorSpaceHighValue = 0 },
        .ddpfPixelFormat = .{ .dwSize = 0, .dwFlags = 0, .dwFourCC = 0, .dwRGBBitCount = 0, .dwRBitMask = 0, .dwGBitMask = 0, .dwBBitMask = 0, .dwRGBAlphaBitMask = 0 },
        .ddsCaps = .{ .dwCaps = DDSCAPS_OFFSCREENPLAIN },
    };
    var surface: ?*Surface = null;
    try std.testing.expectEqual(DD_OK, direct_draw.vtable.CreateSurface(direct_draw, &desc, &surface, null));
    defer _ = surface.?.vtable.Release(surface.?);

    var locked = DDSURFACEDESC{
        .dwSize = @sizeOf(DDSURFACEDESC),
        .dwFlags = 0,
        .dwHeight = 0,
        .dwWidth = 0,
        .lPitch = 0,
        .dwBackBufferCount = 0,
        .dwRefreshRate = 0,
        .dwAlphaBitDepth = 0,
        .dwReserved = 0,
        .lpSurface = null,
        .ddckCKDestOverlay = .{ .dwColorSpaceLowValue = 0, .dwColorSpaceHighValue = 0 },
        .ddckCKDestBlt = .{ .dwColorSpaceLowValue = 0, .dwColorSpaceHighValue = 0 },
        .ddckCKSrcOverlay = .{ .dwColorSpaceLowValue = 0, .dwColorSpaceHighValue = 0 },
        .ddckCKSrcBlt = .{ .dwColorSpaceLowValue = 0, .dwColorSpaceHighValue = 0 },
        .ddpfPixelFormat = .{ .dwSize = 0, .dwFlags = 0, .dwFourCC = 0, .dwRGBBitCount = 0, .dwRBitMask = 0, .dwGBitMask = 0, .dwBBitMask = 0, .dwRGBAlphaBitMask = 0 },
        .ddsCaps = .{ .dwCaps = 0 },
    };
    try std.testing.expectEqual(DD_OK, surface.?.vtable.Lock(surface.?, null, &locked, 0, null));
    try std.testing.expectEqual(@as(DWORD, 8), locked.dwWidth);
    try std.testing.expectEqual(@as(DWORD, 4), locked.dwHeight);
    try std.testing.expectEqual(@as(i32, 8), locked.lPitch);
    try std.testing.expect(locked.lpSurface != null);
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
