const std = @import("std");

const tcpip_object_size = 0x8cb0;
const connected_offset = 0x0a4c;
const connected_size = @sizeOf(c_int);

const FakeTcpipManager = extern struct {
    before_connected: [connected_offset]u8 = [_]u8{0} ** connected_offset,
    Connected: c_int = 0,
    after_connected: [tcpip_object_size - connected_offset - connected_size]u8 = [_]u8{0} ** (tcpip_object_size - connected_offset - connected_size),
};

export var Winsock: FakeTcpipManager align(8) = .{};
export var Server: bool = false;

fn tcpipClose(this: ?*anyopaque) callconv(.c) void {
    _ = this;
}

fn tcpipInit(this: ?*anyopaque) callconv(.c) c_int {
    _ = this;
    return 0;
}

fn tcpipStartServer(this: ?*anyopaque) callconv(.c) void {
    _ = this;
}

fn tcpipStartClient(this: ?*anyopaque) callconv(.c) void {
    _ = this;
}

fn tcpipRead(this: ?*anyopaque, buffer: ?*anyopaque, buffer_len: c_int) callconv(.c) c_int {
    _ = this;
    _ = buffer;
    _ = buffer_len;
    return 0;
}

fn tcpipWrite(this: ?*anyopaque, buffer: ?*anyopaque, buffer_len: c_int) callconv(.c) void {
    _ = this;
    _ = buffer;
    _ = buffer_len;
}

fn tcpipSetHostAddress(this: ?*anyopaque, address: ?[*:0]u8) callconv(.c) void {
    _ = this;
    _ = address;
}

fn tcpipMessageHandler(this: ?*anyopaque, window: ?*anyopaque, message: c_uint, wparam: c_uint, lparam: c_long) callconv(.c) void {
    _ = this;
    _ = window;
    _ = message;
    _ = wparam;
    _ = lparam;
}

comptime {
    @export(&tcpipClose, .{ .name = "_ZN17TcpipManagerClass5CloseEv", .linkage = .strong });
    @export(&tcpipInit, .{ .name = "_ZN17TcpipManagerClass4InitEv", .linkage = .strong });
    @export(&tcpipStartServer, .{ .name = "_ZN17TcpipManagerClass12Start_ServerEv", .linkage = .strong });
    @export(&tcpipStartClient, .{ .name = "_ZN17TcpipManagerClass12Start_ClientEv", .linkage = .strong });
    @export(&tcpipRead, .{ .name = "_ZN17TcpipManagerClass4ReadEPvi", .linkage = .strong });
    @export(&tcpipWrite, .{ .name = "_ZN17TcpipManagerClass5WriteEPvi", .linkage = .strong });
    @export(&tcpipSetHostAddress, .{ .name = "_ZN17TcpipManagerClass16Set_Host_AddressEPc", .linkage = .strong });
    @export(&tcpipMessageHandler, .{ .name = "_ZN17TcpipManagerClass15Message_HandlerEPvjjl", .linkage = .strong });
}

test "fake Winsock object leaves Connected false" {
    try std.testing.expectEqual(@as(c_int, 0), Winsock.Connected);
    try std.testing.expect(!Server);
}

test "disabled TcpipManager Write accepts dropped packets" {
    var payload = [_]u8{ 0x12, 0x34, 0x56 };
    tcpipWrite(&Winsock, &payload, @intCast(payload.len));
}

test "fake Winsock object size matches TcpipManagerClass layout" {
    try std.testing.expectEqual(@as(usize, tcpip_object_size), @sizeOf(@TypeOf(Winsock)));
    try std.testing.expectEqual(@as(usize, connected_offset), @offsetOf(@TypeOf(Winsock), "Connected"));
}
