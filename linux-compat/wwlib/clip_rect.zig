const std = @import("std");

fn signBit(value: u32) bool {
    return (value & 0x80000000) != 0;
}

fn toBits(value: c_int) u32 {
    return @bitCast(@as(i32, @intCast(value)));
}

fn fromBits(bits: u32) c_int {
    return @intCast(@as(i32, @bitCast(bits)));
}

fn negBits(bits: u32) u32 {
    return 0 -% bits;
}

fn outcode(pos: c_int, limit: c_int) u4 {
    var code: u4 = 0;
    code = (code << 1) | @intFromBool(signBit(toBits(pos)));
    code = (code << 1) | @intFromBool(signBit(toBits(pos) -% toBits(limit) -% 1));
    return code;
}

fn rectCode(x: c_int, y: c_int, width: c_int, height: c_int) u4 {
    var code: u4 = 0;
    code = (code << 2) | outcode(x, width);
    code = (code << 2) | outcode(y, height);
    // The original ASM flips the right and bottom bits after shifting in the sign tests.
    return code ^ 0b0101;
}

export fn Clip_Rect(x: *c_int, y: *c_int, dw: *c_int, dh: *c_int, width: c_int, height: c_int) callconv(.c) c_int {
    const x0 = x.*;
    const y0 = y.*;
    const x1 = fromBits(toBits(x0) +% toBits(dw.*));
    const y1 = fromBits(toBits(y0) +% toBits(dh.*));

    const code0 = rectCode(x0, y0, width, height);
    const code1 = rectCode(x1, y1, width, height);

    if ((code0 & code1) != 0) return -1;
    if ((code0 | code1) == 0) return 0;

    if ((code0 & 0b1000) != 0) {
        x.* = 0;
        dw.* = fromBits(toBits(dw.*) +% toBits(x0));
    }

    if ((code0 & 0b0010) != 0) {
        y.* = 0;
        dh.* = fromBits(toBits(dh.*) +% toBits(y0));
    }

    if ((code1 & 0b0100) != 0) {
        dw.* = fromBits(toBits(width) -% toBits(x.*));
        if (dw.* <= 0) return -1;
    }

    if ((code1 & 0b0001) != 0) {
        dh.* = fromBits(toBits(height) -% toBits(y.*));
        if (dh.* <= 0) return -1;
    }

    return 1;
}

fn confineAxis(pos: *c_int, span: c_int, limit: c_int) bool {
    var end_over = toBits(span) +% toBits(pos.*) -% toBits(limit) -% 1;
    const neg_pos = negBits(toBits(pos.*));

    // Mirrors `test -pos, pos + span - limit - 1; jl ok` from CLIPRECT.ASM.
    if (signBit(neg_pos & end_over)) {
        return false;
    }

    if (signBit(neg_pos)) {
        end_over +%= 1;
        pos.* = fromBits(toBits(pos.*) -% end_over);
    } else {
        pos.* = 0;
    }

    return true;
}

export fn Confine_Rect(x: *c_int, y: *c_int, dw: c_int, dh: c_int, width: c_int, height: c_int) callconv(.c) c_int {
    var shifted = confineAxis(x, dw, width);
    shifted = confineAxis(y, dh, height) or shifted;
    return if (shifted) 1 else 0;
}

test "Clip_Rect matches edge and clipping behavior" {
    var x: c_int = 10;
    var y: c_int = 20;
    var w: c_int = 30;
    var h: c_int = 40;
    try std.testing.expectEqual(@as(c_int, 0), Clip_Rect(&x, &y, &w, &h, 100, 100));
    try std.testing.expectEqual(@as(c_int, 10), x);
    try std.testing.expectEqual(@as(c_int, 20), y);
    try std.testing.expectEqual(@as(c_int, 30), w);
    try std.testing.expectEqual(@as(c_int, 40), h);

    x = -5;
    y = -7;
    w = 20;
    h = 30;
    try std.testing.expectEqual(@as(c_int, 1), Clip_Rect(&x, &y, &w, &h, 100, 100));
    try std.testing.expectEqual(@as(c_int, 0), x);
    try std.testing.expectEqual(@as(c_int, 0), y);
    try std.testing.expectEqual(@as(c_int, 15), w);
    try std.testing.expectEqual(@as(c_int, 23), h);

    x = 90;
    y = 80;
    w = 20;
    h = 30;
    try std.testing.expectEqual(@as(c_int, 1), Clip_Rect(&x, &y, &w, &h, 100, 100));
    try std.testing.expectEqual(@as(c_int, 10), w);
    try std.testing.expectEqual(@as(c_int, 20), h);

    x = 100;
    y = 0;
    w = 10;
    h = 10;
    try std.testing.expectEqual(@as(c_int, -1), Clip_Rect(&x, &y, &w, &h, 100, 100));
}

test "Confine_Rect follows assembly edge return behavior" {
    var x: c_int = 10;
    var y: c_int = 20;
    try std.testing.expectEqual(@as(c_int, 0), Confine_Rect(&x, &y, 30, 40, 100, 100));
    try std.testing.expectEqual(@as(c_int, 10), x);
    try std.testing.expectEqual(@as(c_int, 20), y);

    x = -5;
    y = 20;
    try std.testing.expectEqual(@as(c_int, 1), Confine_Rect(&x, &y, 30, 40, 100, 100));
    try std.testing.expectEqual(@as(c_int, 0), x);
    try std.testing.expectEqual(@as(c_int, 20), y);

    x = 95;
    y = 90;
    try std.testing.expectEqual(@as(c_int, 1), Confine_Rect(&x, &y, 30, 40, 100, 100));
    try std.testing.expectEqual(@as(c_int, 70), x);
    try std.testing.expectEqual(@as(c_int, 60), y);

    x = 0;
    y = 20;
    try std.testing.expectEqual(@as(c_int, 1), Confine_Rect(&x, &y, 30, 40, 100, 100));
    try std.testing.expectEqual(@as(c_int, 0), x);
}
