const std = @import("std");

const MpgCommand = enum(c_int) {
    playback_error = -1,
    init = 0,
    cleanup = 1,
    palette = 2,
    update = 3,
};

const MpgResponse = enum(c_int) {
    quit = -1,
    continue_playback = 0,
    lost_focus = 1,
};

const MpgCallback = *const fn (command: MpgCommand, data: ?*anyopaque, user: ?*anyopaque) callconv(.c) MpgResponse;

var registered_callback: ?MpgCallback = null;
var registered_user: ?*anyopaque = null;

export fn MpgSetCallback(callback: ?MpgCallback, user: ?*anyopaque) callconv(.c) void {
    registered_callback = callback;
    registered_user = user;
}

export fn MpgPlay(name: ?[*:0]const u8, direct_draw: ?*anyopaque, surface: ?*anyopaque, dst_rect: ?*anyopaque) callconv(.c) void {
    _ = name;
    _ = direct_draw;
    _ = surface;
    _ = dst_rect;

    const callback = registered_callback orelse return;
    _ = callback(.init, null, registered_user);
    _ = callback(.cleanup, null, registered_user);
}

export fn MpgPause() callconv(.c) void {}

export fn MpgResume() callconv(.c) void {}

test "disabled MPEG playback runs only setup and cleanup callbacks" {
    callback_log = .{};
    var user_marker: u8 = 0x5a;

    MpgSetCallback(testCallback, &user_marker);
    MpgPlay("intro.mpg", null, null, null);

    try std.testing.expectEqualSlices(MpgCommand, &.{ .init, .cleanup }, callback_log.commands[0..callback_log.count]);
    try std.testing.expectEqual(@intFromPtr(&user_marker), @intFromPtr(callback_log.user.?));
}

test "disabled MPEG playback accepts a missing callback" {
    callback_log = .{};

    MpgSetCallback(null, null);
    MpgPlay(null, null, null, null);

    try std.testing.expectEqual(@as(usize, 0), callback_log.count);
}

test "pause and resume leave callback registration unchanged" {
    callback_log = .{};
    var user_marker: u8 = 0x33;

    MpgSetCallback(testCallback, &user_marker);
    MpgPause();
    MpgResume();
    MpgPlay("after-pause.mpg", null, null, null);

    try std.testing.expectEqualSlices(MpgCommand, &.{ .init, .cleanup }, callback_log.commands[0..callback_log.count]);
    try std.testing.expectEqual(@intFromPtr(&user_marker), @intFromPtr(callback_log.user.?));
}

const CallbackLog = struct {
    commands: [8]MpgCommand = undefined,
    count: usize = 0,
    user: ?*anyopaque = null,
};

var callback_log: CallbackLog = .{};

fn testCallback(command: MpgCommand, data: ?*anyopaque, user: ?*anyopaque) callconv(.c) MpgResponse {
    std.debug.assert(data == null);
    callback_log.commands[callback_log.count] = command;
    callback_log.count += 1;
    callback_log.user = user;
    return .continue_playback;
}
