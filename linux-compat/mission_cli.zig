const std = @import("std");

var mission_number: i32 = 0;
var mission_side: u8 = 0;
var scenario_name: [16:0]u8 = [_:0]u8{0} ** 16;

export fn battlecontrolMissionCliReset() callconv(.c) void {
    mission_number = 0;
    mission_side = 0;
    scenario_name[0] = 0;
}

export fn battlecontrolMissionCliConsume(arg_ptr: ?[*:0]const u8, next_ptr: ?[*:0]const u8) callconv(.c) c_int {
    const arg = span(arg_ptr) orelse return 0;

    if (std.ascii.eqlIgnoreCase(arg, "--scenario")) {
        if (span(next_ptr)) |next| {
            setExactScenario(next);
            return 2;
        }
        mission_number = 0;
        mission_side = 0;
        scenario_name[0] = 0;
        return 1;
    }

    if (startsWithIgnoreCase(arg, "--scenario=")) {
        setExactScenario(arg["--scenario=".len..]);
        return 1;
    }

    if (std.ascii.eqlIgnoreCase(arg, "--mission")) {
        if (span(next_ptr)) |next| {
            mission_number = parseMission(next);
            scenario_name[0] = 0;
            return 2;
        }
        mission_number = 0;
        scenario_name[0] = 0;
        return 1;
    }

    if (startsWithIgnoreCase(arg, "--mission=")) {
        mission_number = parseMission(arg["--mission=".len..]);
        scenario_name[0] = 0;
        return 1;
    }

    if (std.ascii.eqlIgnoreCase(arg, "--side")) {
        if (span(next_ptr)) |next| {
            mission_side = parseSide(next);
            scenario_name[0] = 0;
            return 2;
        }
        mission_side = 0;
        scenario_name[0] = 0;
        return 1;
    }

    if (startsWithIgnoreCase(arg, "--side=")) {
        mission_side = parseSide(arg["--side=".len..]);
        scenario_name[0] = 0;
        return 1;
    }

    return 0;
}

export fn battlecontrolMissionCliRequested() callconv(.c) bool {
    return buildScenarioName();
}

export fn battlecontrolMissionCliScenarioName() callconv(.c) [*:0]const u8 {
    _ = buildScenarioName();
    return &scenario_name;
}

fn span(ptr: ?[*:0]const u8) ?[]const u8 {
    const value = ptr orelse return null;
    return std.mem.span(value);
}

fn startsWithIgnoreCase(value: []const u8, prefix: []const u8) bool {
    return value.len >= prefix.len and std.ascii.eqlIgnoreCase(value[0..prefix.len], prefix);
}

fn parseMission(value: []const u8) i32 {
    return std.fmt.parseInt(i32, value, 10) catch 0;
}

fn parseSide(value: []const u8) u8 {
    if (std.ascii.eqlIgnoreCase(value, "allied") or std.ascii.eqlIgnoreCase(value, "allies")) return 'G';
    if (std.ascii.eqlIgnoreCase(value, "soviet") or std.ascii.eqlIgnoreCase(value, "soviets")) return 'U';
    return 0;
}

fn setExactScenario(value: []const u8) void {
    mission_number = 0;
    mission_side = 0;
    scenario_name[0] = 0;

    if (!isScenarioFileName(value)) return;
    for (value, 0..) |character, index| {
        scenario_name[index] = std.ascii.toUpper(character);
    }
    scenario_name[value.len] = 0;
}

fn isScenarioFileName(value: []const u8) bool {
    if (value.len != "SCG01EA.INI".len) return false;
    if (!std.ascii.eqlIgnoreCase(value[0..2], "SC")) return false;
    const side = std.ascii.toUpper(value[2]);
    if (side != 'G' and side != 'U') return false;
    if (!std.ascii.isDigit(value[3]) or !std.ascii.isDigit(value[4])) return false;
    if (std.ascii.toUpper(value[5]) != 'E' and std.ascii.toUpper(value[5]) != 'W') return false;
    const variant = std.ascii.toUpper(value[6]);
    if (variant < 'A' or variant > 'D') return false;
    return std.ascii.eqlIgnoreCase(value[7..], ".INI");
}

fn buildScenarioName() bool {
    if (scenario_name[0] != 0) return true;

    if (mission_number <= 0 or mission_number > 99 or (mission_side != 'G' and mission_side != 'U')) {
        scenario_name[0] = 0;
        return false;
    }

    const formatted = std.fmt.bufPrintZ(scenario_name[0..], "SC{c}{d}{d}EA.INI", .{
        mission_side,
        @divTrunc(mission_number, 10),
        @mod(mission_number, 10),
    }) catch {
        scenario_name[0] = 0;
        return false;
    };
    _ = formatted;
    return true;
}

test "allied mission formats scenario name" {
    battlecontrolMissionCliReset();

    try std.testing.expectEqual(@as(c_int, 2), battlecontrolMissionCliConsume("--side", "allied"));
    try std.testing.expectEqual(@as(c_int, 2), battlecontrolMissionCliConsume("--mission", "3"));

    try std.testing.expect(battlecontrolMissionCliRequested());
    try std.testing.expectEqualStrings("SCG03EA.INI", std.mem.span(battlecontrolMissionCliScenarioName()));
}

test "soviet mission supports equals arguments" {
    battlecontrolMissionCliReset();

    try std.testing.expectEqual(@as(c_int, 1), battlecontrolMissionCliConsume("--side=soviet", null));
    try std.testing.expectEqual(@as(c_int, 1), battlecontrolMissionCliConsume("--mission=12", null));

    try std.testing.expect(battlecontrolMissionCliRequested());
    try std.testing.expectEqualStrings("SCU12EA.INI", std.mem.span(battlecontrolMissionCliScenarioName()));
}

test "invalid mission does not request launch" {
    battlecontrolMissionCliReset();

    _ = battlecontrolMissionCliConsume("--side", "allied");
    _ = battlecontrolMissionCliConsume("--mission", "100");

    try std.testing.expect(!battlecontrolMissionCliRequested());
    try std.testing.expectEqualStrings("", std.mem.span(battlecontrolMissionCliScenarioName()));
}

test "exact scenario argument bypasses mission formatting" {
    battlecontrolMissionCliReset();

    try std.testing.expectEqual(@as(c_int, 2), battlecontrolMissionCliConsume("--scenario", "SCG05EB.INI"));

    try std.testing.expect(battlecontrolMissionCliRequested());
    try std.testing.expectEqualStrings("SCG05EB.INI", std.mem.span(battlecontrolMissionCliScenarioName()));
}

test "exact scenario supports equals argument" {
    battlecontrolMissionCliReset();

    try std.testing.expectEqual(@as(c_int, 1), battlecontrolMissionCliConsume("--scenario=SCU09WD.INI", null));

    try std.testing.expect(battlecontrolMissionCliRequested());
    try std.testing.expectEqualStrings("SCU09WD.INI", std.mem.span(battlecontrolMissionCliScenarioName()));
}

test "invalid exact scenario does not request launch" {
    battlecontrolMissionCliReset();

    try std.testing.expectEqual(@as(c_int, 2), battlecontrolMissionCliConsume("--scenario", "../SCG05EB.INI"));

    try std.testing.expect(!battlecontrolMissionCliRequested());
    try std.testing.expectEqualStrings("", std.mem.span(battlecontrolMissionCliScenarioName()));
}

test "missing exact scenario value clears prior mission request" {
    battlecontrolMissionCliReset();

    _ = battlecontrolMissionCliConsume("--side", "allied");
    _ = battlecontrolMissionCliConsume("--mission", "4");
    try std.testing.expect(battlecontrolMissionCliRequested());

    try std.testing.expectEqual(@as(c_int, 1), battlecontrolMissionCliConsume("--scenario", null));

    try std.testing.expect(!battlecontrolMissionCliRequested());
    try std.testing.expectEqualStrings("", std.mem.span(battlecontrolMissionCliScenarioName()));
}

test "exact scenario only accepts allied and soviet campaign prefixes" {
    battlecontrolMissionCliReset();

    try std.testing.expectEqual(@as(c_int, 1), battlecontrolMissionCliConsume("--scenario=SCZ99WD.INI", null));

    try std.testing.expect(!battlecontrolMissionCliRequested());
    try std.testing.expectEqualStrings("", std.mem.span(battlecontrolMissionCliScenarioName()));
}
