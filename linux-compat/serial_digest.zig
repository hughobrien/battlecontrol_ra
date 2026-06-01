const std = @import("std");

pub fn findDigest(data: []const u8) ?[]const u8 {
    var in_digest = false;
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len == 0 or line[0] == ';') continue;
        if (line[0] == '[') {
            if (std.mem.indexOfScalar(u8, line, ']')) |end| {
                in_digest = std.ascii.eqlIgnoreCase(std.mem.trim(u8, line[1..end], " \t"), "Digest");
            }
            continue;
        }
        if (!in_digest) continue;
        if (std.mem.indexOfScalar(u8, line, '=')) |equals| {
            const key = std.mem.trim(u8, line[0..equals], " \t");
            if (key.len == 1 and key[0] == '1') {
                return std.mem.trim(u8, line[equals + 1 ..], " \t");
            }
        }
    }
    return null;
}

pub fn eqlZSlice(c_string: [*c]const u8, slice: []const u8) bool {
    var index: usize = 0;
    while (index < slice.len) : (index += 1) {
        if (c_string[index] != slice[index]) return false;
    }
    return c_string[index] == 0;
}

test "findDigest reads digest section key one" {
    const text =
        \\[Basic]
        \\Name=Map
        \\
        \\[Digest]
        \\ 1 = abcdef123456
        \\ 2 = ignored
        \\
    ;
    try std.testing.expectEqualStrings("abcdef123456", findDigest(text).?);
}

test "findDigest ignores non-digest sections" {
    const text =
        \\[DigestOld]
        \\1=wrong
        \\[Digest]
        \\2=wrong
    ;
    try std.testing.expect(findDigest(text) == null);
}

test "eqlZSlice requires exact nul-terminated match" {
    try std.testing.expect(eqlZSlice("abc", "abc"));
    try std.testing.expect(!eqlZSlice("abcd", "abc"));
    try std.testing.expect(!eqlZSlice("abc", "abcd"));
}
