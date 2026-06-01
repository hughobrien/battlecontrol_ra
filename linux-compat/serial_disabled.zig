const std = @import("std");
const serial_digest = @import("serial_digest.zig");

const max_serial_packet_size = 256;
const game_normal = 0;
const port_invalid = 1;
const dial_error = 3;
const modem_cmd_error = 3;
const as_success = 0;

const NullModemClass = extern struct {
    vtable: *const anyopaque,
    BuildBuf: [*c]u8,
    MaxLen: c_int,
    EchoBuf: [*c]u8,
    EchoSize: c_int,
    EchoCount: c_int,
    OldIRQPri: c_int,
    ModemVerboseOn: c_int,
    ModemEchoOn: c_int,
    ModemWaitCarrier: c_int,
    ModemCarrierDetect: c_int,
    ModemCarrierLoss: c_int,
    ModemHangupDelay: c_int,
    ModemGuardTime: c_int,
    ModemEscapeCode: u8,
    _pad0: [7]u8,
    Connection: ?*anyopaque,
    NumConnections: c_int,
    _pad1: [4]u8,
    PortHandle: ?*anyopaque,
    NumSend: c_int,
    NumReceive: c_int,
    MagicNum: c_ushort,
    _pad2: [6]u8,
    RXBuf: [*c]u8,
    RXSize: c_int,
    RXCount: c_int,
    RetryDelta: c_ulong,
    MaxRetries: c_ulong,
    Timeout: c_ulong,
    SendOverflows: c_int,
    ReceiveOverflows: c_int,
    CRCErrors: c_int,
    _pad3: [4]u8,
};

const DynamicMissionVector = extern struct {
    vtable: ?*const anyopaque,
    Vector: [*c]?*const MultiMission,
    VectorMax: c_uint,
    flags: c_uint,
    ActiveCount: c_int,
    GrowthStep: c_int,
};

const MultiMission = extern struct {
    ScenarioDescription: [44]u8,
    Filename: [512]u8,
    Digest: [32]u8,
    IsOfficial: bool,
    IsExpansion: bool,
};

const SessionClassPrefix = extern struct {
    _prefix: [168]u8,
    Scenarios: DynamicMissionVector,
};

const CCFileClass = opaque {};

extern var Session: SessionClassPrefix;
extern var NullModem: NullModemClass;
extern fn _ZdaPv(?*anyopaque) callconv(.c) void;
extern fn _ZdlPv(?*anyopaque) callconv(.c) void;
extern fn _ZN11CCFileClassC1EPKc(*CCFileClass, [*:0]const u8) callconv(.c) void;
extern fn _ZN11CCFileClassD2Ev(*CCFileClass) callconv(.c) void;
extern fn _ZN11CCFileClass12Is_AvailableEi(*CCFileClass, c_int) callconv(.c) c_int;
extern fn _ZN11CCFileClass4SizeEv(*CCFileClass) callconv(.c) c_long;
extern fn _ZN11CCFileClass4OpenEi(*CCFileClass, c_int) callconv(.c) c_int;
extern fn _ZN11CCFileClass4ReadEPvl(*CCFileClass, ?*anyopaque, c_long) callconv(.c) c_long;
extern fn _ZN11CCFileClass5CloseEv(*CCFileClass) callconv(.c) void;

var disabled_serial_build_buf: [max_serial_packet_size]u8 = undefined;

export var _ZN14NullModemClass18OrigAbortModemFuncE: ?*const anyopaque = null;
export var _ZN14NullModemClass5InputE: c_int = 0;
export var _ZN14NullModemClass8CommandsE: ?*anyopaque = null;

// No current game code uses RTTI for NullModemClass; Zig cannot cleanly encode
// the Itanium typeinfo vtable+16 relocation here without assembly.
export var _ZTV14NullModemClass: [18]?*const anyopaque = .{
    null,
    null,
    @ptrCast(&_ZN14NullModemClassD1Ev),
    @ptrCast(&_ZN14NullModemClassD0Ev),
    @ptrCast(&_ZN14NullModemClass7ServiceEv),
    @ptrCast(&_ZN14NullModemClass20Send_Private_MessageEPviii),
    @ptrCast(&_ZN14NullModemClass19Get_Private_MessageEPvPiS1_),
    @ptrCast(&_ZN14NullModemClass15Num_ConnectionsEv),
    @ptrCast(&_ZN14NullModemClass13Connection_IDEi),
    @ptrCast(&_ZN14NullModemClass16Connection_IndexEi),
    @ptrCast(&_ZN14NullModemClass15Global_Num_SendEv),
    @ptrCast(&_ZN14NullModemClass18Global_Num_ReceiveEv),
    @ptrCast(&_ZN14NullModemClass16Private_Num_SendEi),
    @ptrCast(&_ZN14NullModemClass19Private_Num_ReceiveEi),
    @ptrCast(&_ZN14NullModemClass19Reset_Response_TimeEv),
    @ptrCast(&_ZN14NullModemClass13Response_TimeEv),
    @ptrCast(&_ZN14NullModemClass10Set_TimingEmmm),
    @ptrCast(&_ZN14NullModemClass15Configure_DebugEiiiPPcii),
};

fn construct(self: *NullModemClass, numsend: c_int, numreceive: c_int, maxlen: c_int, magicnum: c_ushort) void {
    self.vtable = @ptrCast(&_ZTV14NullModemClass[2]);
    self.NumSend = numsend;
    self.NumReceive = numreceive;
    self.MaxLen = @min(maxlen, max_serial_packet_size);
    self.MagicNum = magicnum;
    self.BuildBuf = &disabled_serial_build_buf;
    self.EchoBuf = null;
    self.EchoSize = 0;
    self.EchoCount = 0;
    self.OldIRQPri = -1;
    self.ModemVerboseOn = 0;
    self.ModemEchoOn = 0;
    self.ModemWaitCarrier = 50000;
    self.ModemCarrierDetect = 600;
    self.ModemCarrierLoss = 1400;
    self.ModemHangupDelay = 20000;
    self.ModemGuardTime = 1000;
    self.ModemEscapeCode = '+';
    self.Connection = null;
    self.NumConnections = 0;
    self.PortHandle = null;
    self.RXBuf = null;
    self.RXSize = 0;
    self.RXCount = 0;
    self.RetryDelta = 60;
    self.MaxRetries = std.math.maxInt(c_ulong);
    self.Timeout = 1200;
    self.SendOverflows = 0;
    self.ReceiveOverflows = 0;
    self.CRCErrors = 0;
}

export fn _ZN14NullModemClassC1Eiiit(self: *NullModemClass, numsend: c_int, numreceive: c_int, maxlen: c_int, magicnum: c_ushort) callconv(.c) void {
    construct(self, numsend, numreceive, maxlen, magicnum);
}

export fn _ZN14NullModemClassC2Eiiit(self: *NullModemClass, numsend: c_int, numreceive: c_int, maxlen: c_int, magicnum: c_ushort) callconv(.c) void {
    construct(self, numsend, numreceive, maxlen, magicnum);
}

export fn _ZN14NullModemClassD1Ev(self: *NullModemClass) callconv(.c) void {
    _ = _ZN14NullModemClass17Delete_ConnectionEv(self);
}

export fn _ZN14NullModemClassD2Ev(self: *NullModemClass) callconv(.c) void {
    _ = _ZN14NullModemClass17Delete_ConnectionEv(self);
}

export fn _ZN14NullModemClassD0Ev(self: *NullModemClass) callconv(.c) void {
    _ZN14NullModemClassD1Ev(self);
    _ZdlPv(self);
}

export fn _ZN14NullModemClass4InitEiiPciciii(_: *NullModemClass, _: c_int, _: c_int, _: [*c]u8, _: c_int, _: u8, _: c_int, _: c_int, _: c_int) callconv(.c) c_int {
    return 0;
}

export fn _ZN14NullModemClass17Delete_ConnectionEv(self: *NullModemClass) callconv(.c) c_int {
    self.NumConnections = 0;
    self.BuildBuf = &disabled_serial_build_buf;
    if (self.RXBuf != null) {
        _ZdaPv(self.RXBuf);
        self.RXBuf = null;
    }
    if (self.EchoBuf != null) {
        _ZdaPv(self.EchoBuf);
        self.EchoBuf = null;
    }
    return 1;
}

export fn _ZN14NullModemClass15Num_ConnectionsEv(_: *NullModemClass) callconv(.c) c_int {
    return 0;
}

export fn _ZN14NullModemClass13Connection_IDEi(_: *NullModemClass, _: c_int) callconv(.c) c_int {
    return 0;
}

export fn _ZN14NullModemClass16Connection_IndexEi(_: *NullModemClass, _: c_int) callconv(.c) c_int {
    return 0;
}

export fn _ZN14NullModemClass15Init_Send_QueueEv(_: *NullModemClass) callconv(.c) c_int {
    return 1;
}

export fn _ZN14NullModemClass8ShutdownEv(self: *NullModemClass) callconv(.c) void {
    _ = _ZN14NullModemClass17Delete_ConnectionEv(self);
}

export fn _ZN14NullModemClass10Set_TimingEmmm(self: *NullModemClass, retrydelta: c_ulong, maxretries: c_ulong, timeout: c_ulong) callconv(.c) void {
    self.RetryDelta = retrydelta;
    self.MaxRetries = maxretries;
    self.Timeout = timeout;
}

export fn _ZN14NullModemClass12Send_MessageEPvii(_: *NullModemClass, _: ?*anyopaque, _: c_int, _: c_int) callconv(.c) c_int {
    return 0;
}

export fn _ZN14NullModemClass11Get_MessageEPvPi(_: *NullModemClass, _: ?*anyopaque, buflen: [*c]c_int) callconv(.c) c_int {
    if (buflen != null) buflen.* = 0;
    return 0;
}

export fn _ZN14NullModemClass20Send_Private_MessageEPviii(self: *NullModemClass, buf: ?*anyopaque, buflen: c_int, ack_req: c_int, _: c_int) callconv(.c) c_int {
    return _ZN14NullModemClass12Send_MessageEPvii(self, buf, buflen, ack_req);
}

export fn _ZN14NullModemClass19Get_Private_MessageEPvPiS1_(self: *NullModemClass, buf: ?*anyopaque, buflen: [*c]c_int, _: [*c]c_int) callconv(.c) c_int {
    return _ZN14NullModemClass11Get_MessageEPvPi(self, buf, buflen);
}

export fn _ZN14NullModemClass7ServiceEv(_: *NullModemClass) callconv(.c) c_int {
    return 0;
}

export fn _ZN14NullModemClass8Num_SendEv(_: *NullModemClass) callconv(.c) c_int {
    return 0;
}

export fn _ZN14NullModemClass11Num_ReceiveEv(_: *NullModemClass) callconv(.c) c_int {
    return 0;
}

export fn _ZN14NullModemClass15Global_Num_SendEv(self: *NullModemClass) callconv(.c) c_int {
    return _ZN14NullModemClass8Num_SendEv(self);
}

export fn _ZN14NullModemClass18Global_Num_ReceiveEv(self: *NullModemClass) callconv(.c) c_int {
    return _ZN14NullModemClass11Num_ReceiveEv(self);
}

export fn _ZN14NullModemClass16Private_Num_SendEi(self: *NullModemClass, _: c_int) callconv(.c) c_int {
    return _ZN14NullModemClass8Num_SendEv(self);
}

export fn _ZN14NullModemClass19Private_Num_ReceiveEi(self: *NullModemClass, _: c_int) callconv(.c) c_int {
    return _ZN14NullModemClass11Num_ReceiveEv(self);
}

export fn _ZN14NullModemClass13Response_TimeEv(_: *NullModemClass) callconv(.c) c_ulong {
    return 0;
}

export fn _ZN14NullModemClass19Reset_Response_TimeEv(_: *NullModemClass) callconv(.c) void {}

export fn _ZN14NullModemClass11Oldest_SendEv(_: *NullModemClass) callconv(.c) ?*anyopaque {
    return null;
}

export fn _ZN14NullModemClass15Configure_DebugEiiiPPcii(_: *NullModemClass, _: c_int, _: c_int, _: c_int, _: [*c][*c]u8, _: c_int, _: c_int) callconv(.c) void {}

export fn _ZN14NullModemClass11Detect_PortEP18SerialSettingsType(_: *NullModemClass, _: ?*anyopaque) callconv(.c) c_int {
    return port_invalid;
}

export fn _ZN14NullModemClass12Detect_ModemEP18SerialSettingsTypei(_: *NullModemClass, _: ?*anyopaque, _: c_int) callconv(.c) c_int {
    return 0;
}

export fn _ZN14NullModemClass10Dial_ModemEPc14DialMethodTypei(_: *NullModemClass, _: [*c]u8, _: c_int, _: c_int) callconv(.c) c_int {
    return dial_error;
}

export fn _ZN14NullModemClass12Answer_ModemEi(_: *NullModemClass, _: c_int) callconv(.c) c_int {
    return dial_error;
}

export fn _ZN14NullModemClass12Hangup_ModemEv(_: *NullModemClass) callconv(.c) c_int {
    return 0;
}

export fn _ZN14NullModemClass16Setup_Modem_EchoEPFvcE(_: *NullModemClass, _: ?*const anyopaque) callconv(.c) void {}
export fn _ZN14NullModemClass17Remove_Modem_EchoEv(_: *NullModemClass) callconv(.c) void {}
export fn _ZN14NullModemClass13Print_EchoBufEv(_: *NullModemClass) callconv(.c) void {}
export fn _ZN14NullModemClass13Reset_EchoBufEv(_: *NullModemClass) callconv(.c) void {}

export fn _ZN14NullModemClass11Abort_ModemEP4PORT(_: ?*anyopaque) callconv(.c) c_int {
    return 0;
}

export fn _ZN14NullModemClass17Setup_Abort_ModemEv(_: *NullModemClass) callconv(.c) void {}
export fn _ZN14NullModemClass18Remove_Abort_ModemEv(_: *NullModemClass) callconv(.c) void {}

export fn _ZN14NullModemClass19Change_IRQ_PriorityEi(_: *NullModemClass, _: c_int) callconv(.c) c_int {
    return as_success;
}

export fn _ZN14NullModemClass16Get_Modem_StatusEv(_: *NullModemClass) callconv(.c) c_int {
    return 0;
}

export fn _ZN14NullModemClass18Send_Modem_CommandEPccS0_iii(_: *NullModemClass, _: [*c]u8, _: u8, buffer: [*c]u8, buflen: c_int, _: c_int, _: c_int) callconv(.c) c_int {
    if (buffer != null and buflen > 0) buffer[0] = 0;
    return modem_cmd_error;
}

export fn _ZN14NullModemClass25Verify_And_Convert_To_IntEPc(_: *NullModemClass, _: [*c]u8) callconv(.c) c_int {
    return -1;
}

export fn _Z15Init_Null_ModemP18SerialSettingsType(_: ?*anyopaque) callconv(.c) c_int {
    return 0;
}

export fn _Z14Shutdown_Modemv() callconv(.c) void {
    _ZN14NullModemClass8ShutdownEv(&NullModem);
}

export fn _Z13Modem_Signoffv() callconv(.c) void {}

export fn _Z15Test_Null_Modemv() callconv(.c) c_int {
    return 0;
}

export fn _Z15Reconnect_Modemv() callconv(.c) c_int {
    return 0;
}

export fn _Z23Destroy_Null_Connectionii(_: c_int, _: c_int) callconv(.c) void {
    _ = _ZN14NullModemClass17Delete_ConnectionEv(&NullModem);
}

export fn _Z20Select_Serial_Dialogv() callconv(.c) c_int {
    return game_normal;
}

export fn _Z19Com_Scenario_Dialogb(_: bool) callconv(.c) c_int {
    return 0;
}

export fn _Z24Com_Show_Scenario_Dialogv() callconv(.c) c_int {
    return 0;
}

export fn _Z19Find_Local_ScenarioPcS_jS_b(description: [*c]const u8, filename: [*c]u8, length: c_uint, digest: [*c]const u8, official: bool) callconv(.c) bool {
    var index: c_int = 0;
    while (index < Session.Scenarios.ActiveCount) : (index += 1) {
        const mission = Session.Scenarios.Vector[@intCast(index)] orelse continue;
        if (std.mem.orderZ(u8, @ptrCast(&mission.ScenarioDescription), description) != .eq) continue;

        var file_storage: [168]u8 align(8) = undefined;
        const file: *CCFileClass = @ptrCast(&file_storage);
        _ZN11CCFileClassC1EPKc(file, @ptrCast(&mission.Filename));
        defer _ZN11CCFileClassD2Ev(file);

        if (_ZN11CCFileClass12Is_AvailableEi(file, 0) == 0) continue;
        if (_ZN11CCFileClass4SizeEv(file) != @as(c_long, @intCast(length))) continue;

        if (!official and !fileDigestMatches(file, digest)) continue;

        copyZ(filename, @ptrCast(&mission.Filename));
        return true;
    }

    return false;
}

fn fileDigestMatches(file: *CCFileClass, expected: [*c]const u8) bool {
    const size = _ZN11CCFileClass4SizeEv(file);
    if (size <= 0) return std.mem.orderZ(u8, expected, "No digest here mate. Nope.") == .eq;
    if (_ZN11CCFileClass4OpenEi(file, 1) == 0) return false;
    defer _ZN11CCFileClass5CloseEv(file);

    const usize_size: usize = @intCast(size);
    const data = std.heap.c_allocator.alloc(u8, usize_size) catch return false;
    defer std.heap.c_allocator.free(data);

    const got = _ZN11CCFileClass4ReadEPvl(file, data.ptr, size);
    if (got <= 0) return false;

    const digest = serial_digest.findDigest(data[0..@intCast(got)]) orelse "No digest here mate. Nope.";
    return serial_digest.eqlZSlice(expected, digest);
}

fn copyZ(dest: [*c]u8, source: [*c]const u8) void {
    var i: usize = 0;
    while (source[i] != 0) : (i += 1) {
        dest[i] = source[i];
    }
    dest[i] = 0;
}

comptime {
    std.debug.assert(@sizeOf(NullModemClass) == 176);
    std.debug.assert(@offsetOf(NullModemClass, "BuildBuf") == 8);
    std.debug.assert(@offsetOf(NullModemClass, "CRCErrors") == 168);
    std.debug.assert(@sizeOf(MultiMission) == 590);
    std.debug.assert(@offsetOf(SessionClassPrefix, "Scenarios") == 168);
    std.debug.assert(@offsetOf(DynamicMissionVector, "ActiveCount") == 24);
}
