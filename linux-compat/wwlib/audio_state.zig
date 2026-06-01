const std = @import("std");

const FocusLossCallback = *const fn () callconv(.c) void;

export var StreamLowImpact: c_int = 0;
export var Misc: c_int = 0;
export var SoundType: c_int = 0;
export var SampleType: c_int = 0;
export var Audio_Focus_Loss_Function: ?FocusLossCallback = null;

var score_volume: c_int = 0;

fn audioInit(window: ?*anyopaque, bits_per_sample: c_int, stereo: c_int, rate: c_int, reverse_channels: c_int) callconv(.c) c_int {
    _ = window;
    _ = bits_per_sample;
    _ = stereo;
    _ = rate;
    _ = reverse_channels;
    SampleType = 0;
    SoundType = 0;
    return 0;
}

fn soundEnd() callconv(.c) void {
    SampleType = 0;
    SoundType = 0;
}

fn stopSample(handle: c_int) callconv(.c) void {
    _ = handle;
}

fn sampleStatus(handle: c_int) callconv(.c) c_int {
    _ = handle;
    return 0;
}

fn isSamplePlaying(sample: ?*const anyopaque) callconv(.c) c_int {
    _ = sample;
    return 0;
}

fn stopSamplePlaying(sample: ?*const anyopaque) callconv(.c) void {
    _ = sample;
}

fn playSample(sample: ?*const anyopaque, priority: c_int, volume: c_int, panloc: c_short) callconv(.c) c_int {
    _ = sample;
    _ = priority;
    _ = volume;
    _ = panloc;
    return -1;
}

fn setScoreVol(volume: c_int) callconv(.c) c_int {
    const old = score_volume;
    score_volume = volume & 0xff;
    return old;
}

fn fadeSample(handle: c_int, ticks: c_int) callconv(.c) void {
    _ = handle;
    _ = ticks;
}

fn fileStreamSampleVol(filename: ?[*:0]const u8, volume: c_int, real_time_start: c_int) callconv(.c) c_int {
    _ = filename;
    _ = volume;
    _ = real_time_start;
    return -1;
}

fn soundCallback() callconv(.c) void {}

fn getDigiHandle() callconv(.c) c_int {
    return -1;
}

fn setPrimaryBufferFormat() callconv(.c) c_int {
    return 0;
}

fn startPrimarySoundBuffer(forced: c_int) callconv(.c) c_int {
    _ = forced;
    return 0;
}

fn stopPrimarySoundBuffer() callconv(.c) void {}

fn vqaPauseAudio() callconv(.c) void {}

fn vqaResumeAudio() callconv(.c) void {}

comptime {
    @export(&audioInit, .{ .name = "_Z10Audio_InitPviiii", .linkage = .strong });
    @export(&soundEnd, .{ .name = "_Z9Sound_Endv", .linkage = .strong });
    @export(&stopSample, .{ .name = "_Z11Stop_Samplei", .linkage = .strong });
    @export(&sampleStatus, .{ .name = "_Z13Sample_Statusi", .linkage = .strong });
    @export(&isSamplePlaying, .{ .name = "_Z17Is_Sample_PlayingPKv", .linkage = .strong });
    @export(&stopSamplePlaying, .{ .name = "_Z19Stop_Sample_PlayingPKv", .linkage = .strong });
    @export(&playSample, .{ .name = "_Z11Play_SamplePKviis", .linkage = .strong });
    @export(&setScoreVol, .{ .name = "_Z13Set_Score_Voli", .linkage = .strong });
    @export(&fadeSample, .{ .name = "_Z11Fade_Sampleii", .linkage = .strong });
    @export(&fileStreamSampleVol, .{ .name = "_Z22File_Stream_Sample_VolPKcii", .linkage = .strong });
    @export(&soundCallback, .{ .name = "_Z14Sound_Callbackv", .linkage = .strong });
    @export(&getDigiHandle, .{ .name = "_Z15Get_Digi_Handlev", .linkage = .strong });
    @export(&setPrimaryBufferFormat, .{ .name = "_Z25Set_Primary_Buffer_Formatv", .linkage = .strong });
    @export(&startPrimarySoundBuffer, .{ .name = "_Z26Start_Primary_Sound_Bufferi", .linkage = .strong });
    @export(&stopPrimarySoundBuffer, .{ .name = "_Z25Stop_Primary_Sound_Bufferv", .linkage = .strong });
    @export(&vqaPauseAudio, .{ .name = "_Z14VQA_PauseAudiov", .linkage = .strong });
    @export(&vqaResumeAudio, .{ .name = "_Z15VQA_ResumeAudiov", .linkage = .strong });
}

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

test "disabled audio initialization reports no digital device" {
    try std.testing.expectEqual(@as(c_int, 0), audioInit(null, 16, 0, 22050, 0));
    try std.testing.expectEqual(@as(c_int, -1), getDigiHandle());
}

test "disabled sample playback never starts" {
    var sample = [_]u8{ 0x01, 0x02, 0x03, 0x04 };

    try std.testing.expectEqual(@as(c_int, -1), playSample(&sample, 0xff, 0xff, 0));
    try std.testing.expectEqual(@as(c_int, -1), fileStreamSampleVol("theme.aud", 0xff, 1));
    try std.testing.expectEqual(@as(c_int, 0), sampleStatus(0));
    try std.testing.expectEqual(@as(c_int, 0), isSamplePlaying(&sample));

    stopSample(0);
    stopSamplePlaying(&sample);
    fadeSample(0, 1);
    soundCallback();
    soundEnd();
}

test "disabled score volume stores the masked setting and returns the previous value" {
    score_volume = 0;

    try std.testing.expectEqual(@as(c_int, 0), setScoreVol(0x123));
    try std.testing.expectEqual(@as(c_int, 0x23), setScoreVol(0x45));
}

test "disabled primary buffer operations fail without side effects" {
    try std.testing.expectEqual(@as(c_int, 0), setPrimaryBufferFormat());
    try std.testing.expectEqual(@as(c_int, 0), startPrimarySoundBuffer(1));
    stopPrimarySoundBuffer();
}

test "disabled VQA audio pause and resume are no-ops" {
    vqaPauseAudio();
    vqaResumeAudio();
}

fn testFocusLoss() callconv(.c) void {}
