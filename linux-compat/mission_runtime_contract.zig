const std = @import("std");

fn readFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    return try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        path,
        allocator,
        .limited(512 * 1024),
    );
}

test "threat evaluation does not index mission controls for MISSION_NONE" {
    const source = try readFile(std.testing.allocator, "CODE/TECHNO.CPP");
    defer std.testing.allocator.free(source);

    try std.testing.expect(std.mem.indexOf(u8, source, "object->Mission != MISSION_NONE && MissionControl[object->Mission].IsNoThreat") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "if (MissionControl[object->Mission].IsNoThreat)") == null);
    try std.testing.expect(std.mem.indexOf(u8, source, "MissionControl[infantry->Mission]") == null);
    try std.testing.expect(std.mem.indexOf(u8, source, "MissionControl[unit->Mission]") == null);
    try std.testing.expect(std.mem.indexOf(u8, source, "MissionClass::Is_Recruitable_Mission(infantry->Mission)") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "MissionClass::Is_Recruitable_Mission(unit->Mission)") != null);
}

test "AI team formation speed does not use player team arrays for generated groups" {
    const source = try readFile(std.testing.allocator, "CODE/TEAM.CPP");
    defer std.testing.allocator.free(source);

    const start = std.mem.indexOf(u8, source, "int TeamClass::TMission_Formation(void)") orelse return error.MissingFormationMission;
    const end = std.mem.indexOfPos(u8, source, start, "// Advance past the formation-setting command.") orelse return error.MissingFormationEnd;
    const body = source[start..end];

    try std.testing.expect(std.mem.indexOf(u8, body, "SpeedType team_speed") != null);
    try std.testing.expect(std.mem.indexOf(u8, body, "MPHType team_max_speed") != null);
    try std.testing.expect(std.mem.indexOf(u8, body, "TeamSpeed[group]") == null);
    try std.testing.expect(std.mem.indexOf(u8, body, "TeamMaxSpeed[group]") == null);
}

test "threat distance scaling keeps legacy 32-bit wrap explicit" {
    const source = try readFile(std.testing.allocator, "CODE/TECHNO.CPP");
    defer std.testing.allocator.free(source);

    try std.testing.expect(std.mem.indexOf(u8, source, "value = (value * 32000)") == null);
    try std.testing.expect(std.mem.indexOf(u8, source, "(uint32_t)value * 32000U") != null);
}
