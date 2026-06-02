const std = @import("std");

const BOOL = c_int;
const DWORD = u32;
const LONG = c_long;
const HRESULT = LONG;
const BYTE = u8;
const HANDLE = ?*anyopaque;
const HWND = ?*anyopaque;

extern fn ddrawMiniSdlSetDisplayMode(width: DWORD, height: DWORD, bits_per_pixel: DWORD) callconv(.c) c_int;
extern fn ddrawMiniSdlShutdown() callconv(.c) void;
extern fn ddrawMiniSdlPresentIndexedSurface(
    indexed_pixels: ?[*]const u8,
    pitch: usize,
    width: usize,
    height: usize,
    palette: ?[*]const PALETTEENTRY,
) callconv(.c) c_int;

const RECT = extern struct {
    left: LONG,
    top: LONG,
    right: LONG,
    bottom: LONG,
};

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

var primary_surface: ?*Surface = null;

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
    if (remaining == 0) {
        ddrawMiniSdlShutdown();
        std.c.free(self);
    }
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
    if ((caps & DDSCAPS_PRIMARYSURFACE) != 0) primary_surface = surface;
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
    primary_surface = null;
    ddrawMiniSdlShutdown();
    return DD_OK;
}

fn directDrawSetCooperativeLevel(_: *DirectDraw, _: HWND, _: DWORD) callconv(.c) HRESULT {
    return DD_OK;
}

fn directDrawSetDisplayMode(self: *DirectDraw, width: DWORD, height: DWORD, bits_per_pixel: DWORD) callconv(.c) HRESULT {
    if (ddrawMiniSdlSetDisplayMode(width, height, bits_per_pixel) == 0) return DDERR_GENERIC;
    primary_surface = null;
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
    if (primary_surface) |surface| {
        if (surface.palette == self) presentSurface(surface);
    }
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
        if (primary_surface == self) primary_surface = null;
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

fn presentSurface(surface: *Surface) void {
    if ((surface.caps & DDSCAPS_PRIMARYSURFACE) == 0) return;
    const buffer = surface.buffer orelse return;
    const palette = surface.palette orelse return;
    if (surface.pitch < 0) return;
    _ = ddrawMiniSdlPresentIndexedSurface(
        buffer,
        @intCast(surface.pitch),
        surface.width,
        surface.height,
        &palette.entries,
    );
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
        presentSurface(self);
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
    presentSurface(self);
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

fn surfaceFlip(self: *Surface, _: ?*Surface, _: DWORD) callconv(.c) HRESULT {
    presentSurface(self);
    return DD_OK;
}

fn surfaceGetAttachedSurface(self: *Surface, _: ?*DDSCAPS, out: ?*?*Surface) callconv(.c) HRESULT {
    const surface_out = out orelse return DDERR_INVALIDPARAMS;
    const attached = self.attached orelse {
        surface_out.* = null;
        return E_NOTIMPL;
    };
    _ = surfaceAddRef(attached);
    surface_out.* = attached;
    return DD_OK;
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
    presentSurface(self);
    return DD_OK;
}

fn surfaceUnlock(self: *Surface, _: ?*anyopaque) callconv(.c) HRESULT {
    presentSurface(self);
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

test "GetAttachedSurface returns a releaseable surface reference" {
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
    defer {
        if (surface) |value| _ = value.vtable.Release(value);
    }

    var attached: ?*Surface = null;
    try std.testing.expectEqual(DD_OK, direct_draw.vtable.CreateSurface(direct_draw, &desc, &attached, null));
    defer {
        if (attached) |value| _ = value.vtable.Release(value);
    }

    try std.testing.expectEqual(DD_OK, surface.?.vtable.AddAttachedSurface(surface.?, attached.?));

    var caps = DDSCAPS{ .dwCaps = DDSCAPS_OFFSCREENPLAIN };
    var fetched: ?*Surface = null;
    try std.testing.expectEqual(DD_OK, surface.?.vtable.GetAttachedSurface(surface.?, &caps, &fetched));
    try std.testing.expectEqual(attached.?, fetched.?);
    try std.testing.expectEqual(@as(c_ulong, 2), attached.?.ref_count);
    try std.testing.expectEqual(@as(c_ulong, 1), fetched.?.vtable.Release(fetched.?));
}
