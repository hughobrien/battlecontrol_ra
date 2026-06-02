const std = @import("std");

var scenario_ready_file: ?[*:0]const u8 = null;

export fn battlecontrolSetScenarioReadyFile(path: ?[*:0]const u8) callconv(.c) void {
    scenario_ready_file = path;
}

export fn battlecontrolScenarioStarted(name: ?[*:0]const u8) callconv(.c) void {
    const raw_path = scenario_ready_file orelse return;
    const raw_name = name orelse return;
    const path = std.mem.span(raw_path);
    const scenario = std.mem.span(raw_name);
    if (path.len == 0 or scenario.len == 0) return;

    const io = std.Io.Threaded.global_single_threaded.io();
    writeScenarioReady(io, std.Io.Dir.cwd(), path, scenario) catch {};
}

fn writeScenarioReady(io: std.Io, dir: std.Io.Dir, path: []const u8, scenario: []const u8) !void {
    var file = try dir.createFile(io, path, .{ .truncate = true });
    defer file.close(io);
    try file.writeStreamingAll(io, "scenario=");
    try file.writeStreamingAll(io, scenario);
    try file.writeStreamingAll(io, "\n");
}

test "scenario ready file records loaded scenario name" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try writeScenarioReady(std.testing.io, tmp.dir, "scenario.ready", "SCG05EB.INI");

    const file = try tmp.dir.openFile(std.testing.io, "scenario.ready", .{});
    defer file.close(std.testing.io);

    var bytes: [64]u8 = undefined;
    const read = try file.readPositionalAll(std.testing.io, &bytes, 0);
    try std.testing.expectEqualStrings("scenario=SCG05EB.INI\n", bytes[0..read]);
}
