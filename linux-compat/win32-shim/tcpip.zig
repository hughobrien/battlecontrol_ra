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

fn tcpipClose(this: ?*anyopaque) callconv(.c) void {
    _ = this;
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
    @export(&tcpipMessageHandler, .{ .name = "_ZN17TcpipManagerClass15Message_HandlerEPvjjl", .linkage = .strong });
}

test "fake Winsock object leaves Connected false" {
    try std.testing.expectEqual(@as(c_int, 0), Winsock.Connected);
}

test "fake Winsock object size matches TcpipManagerClass layout" {
    try std.testing.expectEqual(@as(usize, tcpip_object_size), @sizeOf(@TypeOf(Winsock)));
    try std.testing.expectEqual(@as(usize, connected_offset), @offsetOf(@TypeOf(Winsock), "Connected"));
}
