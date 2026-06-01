export fn Stop_Profiler() callconv(.c) void {}

test "Stop_Profiler is callable as an inactive profiler stop hook" {
    Stop_Profiler();
}
