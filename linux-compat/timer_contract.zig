const std = @import("std");

fn readTimerIni(allocator: std.mem.Allocator) ![]u8 {
    return try std.Io.Dir.cwd().readFileAlloc(
        std.testing.io,
        "WIN32LIB/TIMER/TIMERINI.CPP",
        allocator,
        .limited(128 * 1024),
    );
}

test "WinTimerClass keeps the retail timeSetEvent callback path" {
    const source = try readTimerIni(std.testing.allocator);
    defer std.testing.allocator.free(source);

    try std.testing.expect(std.mem.indexOf(u8, source,
        "TimerHandle = timeSetEvent ( 1000/freq , 1 , Timer_Callback , 0 , TIME_PERIODIC);",
    ) != null);

    try std.testing.expect(std.mem.indexOf(u8, source,
        "#ifndef _MSC_VER\n\tSysTicks = timeGetTime();",
    ) == null);
}

test "WinTimerClass tick getters expose callback-maintained counters" {
    const source = try readTimerIni(std.testing.allocator);
    defer std.testing.allocator.free(source);

    try std.testing.expect(std.mem.indexOf(u8, source,
        "return ( SysTicks );",
    ) != null);
    try std.testing.expect(std.mem.indexOf(u8, source,
        "return ( UserTicks );",
    ) != null);

    try std.testing.expect(std.mem.indexOf(u8, source,
        "timeGetTime() - SysTicks",
    ) == null);
    try std.testing.expect(std.mem.indexOf(u8, source,
        "timeGetTime() - UserTicks",
    ) == null);
}
