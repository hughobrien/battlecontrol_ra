const std = @import("std");

const FocusLossCallback = *const fn () callconv(.c) void;

export var StreamLowImpact: c_int = 0;
export var Misc: c_int = 0;
export var SoundType: c_int = 0;
export var SampleType: c_int = 0;
export var Audio_Focus_Loss_Function: ?FocusLossCallback = null;

test "audio globals start with the SOUNDIO defaults" {
    try std.testing.expectEqual(@as(c_int, 0), StreamLowImpact);
    try std.testing.expectEqual(@as(c_int, 0), Misc);
    try std.testing.expectEqual(@as(c_int, 0), SoundType);
    try std.testing.expectEqual(@as(c_int, 0), SampleType);
    try std.testing.expectEqual(null, Audio_Focus_Loss_Function);
}

test "audio globals are writable like C storage" {
    StreamLowImpact = 1;
    Misc = 1234;
    SoundType = 2;
    SampleType = 3;
    Audio_Focus_Loss_Function = testFocusLoss;

    try std.testing.expectEqual(@as(c_int, 1), StreamLowImpact);
    try std.testing.expectEqual(@as(c_int, 1234), Misc);
    try std.testing.expectEqual(@as(c_int, 2), SoundType);
    try std.testing.expectEqual(@as(c_int, 3), SampleType);
    try std.testing.expectEqual(@intFromPtr(&testFocusLoss), @intFromPtr(Audio_Focus_Loss_Function.?));

    StreamLowImpact = 0;
    Misc = 0;
    SoundType = 0;
    SampleType = 0;
    Audio_Focus_Loss_Function = null;
}

fn testFocusLoss() callconv(.c) void {}
