const std = @import("std");
const builtin = @import("builtin");

const icon_width = 24;
const icon_height = 24;
const max_icon_sets = 100;
const max_lookup_entries = 3000;

const IControl = extern struct {
    width: u16,
    height: u16,
    count: u16,
    allocated: u16,
    map_width: u16,
    map_height: u16,
    size: c_int,
    icons: c_int,
    palettes: c_int,
    remaps: c_int,
    trans_flag: c_int,
    color_map: c_int,
    map: c_int,
};

const IconSetRegistration = extern struct {
    icon_set_ptr: ?*const IControl,
    icon_list_offset: c_int,
};

const StampInfo = struct {
    last_icon_set: ?*const IControl = null,
    map_base: ?[*]const u8 = null,
    icon_count: c_int = 0,
    icon_size: usize = 0,
    stamp_base: [*]u8 = undefined,
};

extern var IconSetList: [max_icon_sets]IconSetRegistration;
extern var IconCacheLookup: [max_lookup_entries]c_short;
extern fn Get_Free_Cache_Slot() callconv(.c) c_int;
extern fn Cache_New_Icon(icon_index: c_int, icon_ptr: ?*anyopaque) callconv(.c) c_int;

var stamp_info: StampInfo = .{};

const test_state = struct {
    var icon_set_list = [_]IconSetRegistration{.{ .icon_set_ptr = null, .icon_list_offset = 0 }} ** max_icon_sets;
    var icon_cache_lookup = [_]c_short{-1} ** max_lookup_entries;
    var next_free_slot: c_int = -1;
    var cache_new_result: c_int = 0;
    var cache_new_icon_index: c_int = -1;
    var cache_new_icon_ptr: ?*anyopaque = null;
};

fn registeredIconSets() *[max_icon_sets]IconSetRegistration {
    if (builtin.is_test) return &test_state.icon_set_list;
    return &IconSetList;
}

fn iconLookupTable() *[max_lookup_entries]c_short {
    if (builtin.is_test) return &test_state.icon_cache_lookup;
    return &IconCacheLookup;
}

fn getFreeCacheSlot() c_int {
    if (builtin.is_test) return test_state.next_free_slot;
    return Get_Free_Cache_Slot();
}

fn cacheNewIcon(icon_index: c_int, icon_ptr: ?*anyopaque) c_int {
    if (builtin.is_test) {
        test_state.cache_new_icon_index = icon_index;
        test_state.cache_new_icon_ptr = icon_ptr;
        return test_state.cache_new_result;
    }
    return Cache_New_Icon(icon_index, icon_ptr);
}

export fn Cache_Copy_Icon(icon_ptr: *const anyopaque, dest_ptr: *anyopaque, pitch: c_int) callconv(.c) void {
    var source: [*]const u8 = @ptrCast(icon_ptr);
    var destination: [*]u8 = @ptrCast(dest_ptr);

    var row: usize = 0;
    while (row != icon_height) : (row += 1) {
        @memcpy(destination[0..icon_width], source[0..icon_width]);
        source += icon_width;
        destination = addSigned(destination, pitch);
    }
}

export fn Is_Icon_Cached(icon_data: ?*const IControl, icon: c_int) callconv(.c) c_int {
    const icon_set = icon_data orelse return -1;
    return isIconCached(icon_set, icon);
}

fn isIconCached(icon_set: *const IControl, requested_icon: c_int) c_int {
    if (requested_icon < 0) return -1;

    const stamp = initStamps(icon_set);
    const actual_icon = mappedIcon(stamp, requested_icon);
    if (actual_icon < 0 or actual_icon >= stamp.icon_count) return -1;

    const registration = findRegisteredIconSet(icon_set) orelse return -1;
    const lookup_index = @as(c_int, @divTrunc(registration.icon_list_offset, 2)) + actual_icon;
    if (lookup_index < 0 or lookup_index >= max_lookup_entries) return -1;

    const lookup: *[max_lookup_entries]c_short = iconLookupTable();
    const cached_index = lookup[@intCast(lookup_index)];
    if (cached_index != -1) return @intCast(@as(u16, @bitCast(cached_index)));

    const free_slot = getFreeCacheSlot();
    if (free_slot < 0) return -1;

    const icon_ptr = iconPointer(stamp, actual_icon);
    if (cacheNewIcon(free_slot, icon_ptr) == 0) return -1;

    lookup[@intCast(lookup_index)] = @intCast(free_slot);
    return free_slot;
}

fn initStamps(icon_set: *const IControl) *const StampInfo {
    if (stamp_info.last_icon_set == icon_set) return &stamp_info;

    stamp_info.last_icon_set = icon_set;
    stamp_info.map_base = if (icon_set.map == 0) null else addByteOffsetConst(icon_set, icon_set.map);
    stamp_info.icon_count = @intCast(icon_set.count);
    stamp_info.icon_size = @as(usize, @intCast(icon_set.width)) * @as(usize, @intCast(icon_set.height));
    stamp_info.stamp_base = addByteOffset(icon_set, icon_set.icons);
    return &stamp_info;
}

fn mappedIcon(stamp: *const StampInfo, requested_icon: c_int) c_int {
    const map_base = stamp.map_base orelse return requested_icon;

    return (requested_icon & ~@as(c_int, 0xff)) | map_base[@intCast(requested_icon)];
}

fn iconPointer(stamp: *const StampInfo, icon: c_int) ?*anyopaque {
    const icon_offset = @as(usize, @intCast(icon)) * stamp.icon_size;
    return stamp.stamp_base + icon_offset;
}

fn findRegisteredIconSet(icon_set: *const IControl) ?IconSetRegistration {
    for (registeredIconSets()) |registration| {
        if (registration.icon_set_ptr == icon_set) return registration;
    }
    return null;
}

fn addByteOffset(base: *const anyopaque, offset: c_int) [*]u8 {
    const address = @intFromPtr(base);
    if (offset >= 0) return @ptrFromInt(address + @as(usize, @intCast(offset)));
    return @ptrFromInt(address - @as(usize, @intCast(-offset)));
}

fn addByteOffsetConst(base: *const anyopaque, offset: c_int) [*]const u8 {
    return @ptrCast(addByteOffset(base, offset));
}

fn addSigned(pointer: [*]u8, offset: c_int) [*]u8 {
    const address = @intFromPtr(pointer);
    if (offset >= 0) return @ptrFromInt(address + @as(usize, @intCast(offset)));
    return @ptrFromInt(address - @as(usize, @intCast(-offset)));
}

test "Cache_Copy_Icon copies a packed 24 by 24 icon" {
    var source: [icon_width * icon_height]u8 = undefined;
    for (&source, 0..) |*byte, index| {
        byte.* = @truncate(index);
    }

    var destination = [_]u8{0} ** (icon_width * icon_height);

    Cache_Copy_Icon(&source, &destination, icon_width);

    try std.testing.expectEqualSlices(u8, &source, &destination);
}

test "Cache_Copy_Icon preserves destination pitch padding" {
    const pitch = icon_width + 5;
    var source: [icon_width * icon_height]u8 = undefined;
    for (&source, 0..) |*byte, index| {
        byte.* = @truncate((index * 7) + 3);
    }

    var destination = [_]u8{0xcc} ** (pitch * icon_height);

    Cache_Copy_Icon(&source, &destination, pitch);

    var row: usize = 0;
    while (row != icon_height) : (row += 1) {
        const source_start = row * icon_width;
        const dest_start = row * pitch;
        try std.testing.expectEqualSlices(
            u8,
            source[source_start..][0..icon_width],
            destination[dest_start..][0..icon_width],
        );
        try std.testing.expectEqualSlices(
            u8,
            &[_]u8{0xcc} ** (pitch - icon_width),
            destination[dest_start + icon_width ..][0 .. pitch - icon_width],
        );
    }
}

test "Cache_Copy_Icon supports a negative destination pitch" {
    const pitch = -@as(c_int, icon_width);
    var source: [icon_width * icon_height]u8 = undefined;
    for (&source, 0..) |*byte, index| {
        byte.* = @truncate((index * 5) + 1);
    }

    var destination = [_]u8{0} ** (icon_width * icon_height);
    const last_row_start = icon_width * (icon_height - 1);

    Cache_Copy_Icon(&source, &destination[last_row_start], pitch);

    var row: usize = 0;
    while (row != icon_height) : (row += 1) {
        const source_start = row * icon_width;
        const dest_start = (icon_height - 1 - row) * icon_width;
        try std.testing.expectEqualSlices(
            u8,
            source[source_start..][0..icon_width],
            destination[dest_start..][0..icon_width],
        );
    }
}

test "Is_Icon_Cached returns an existing cache table hit" {
    resetIconCacheTestState();
    var icon_set = makeIconSet(4);
    test_state.icon_set_list[0] = .{ .icon_set_ptr = &icon_set.control, .icon_list_offset = 6 };
    test_state.icon_cache_lookup[3 + 2] = 42;

    try std.testing.expectEqual(@as(c_int, 42), Is_Icon_Cached(&icon_set.control, 2));
    try std.testing.expectEqual(@as(c_int, -1), test_state.cache_new_icon_index);
}

test "IControl layout matches the 32-bit STAMP.INC structure" {
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(IControl, "width"));
    try std.testing.expectEqual(@as(usize, 2), @offsetOf(IControl, "height"));
    try std.testing.expectEqual(@as(usize, 4), @offsetOf(IControl, "count"));
    try std.testing.expectEqual(@as(usize, 6), @offsetOf(IControl, "allocated"));
    try std.testing.expectEqual(@as(usize, 8), @offsetOf(IControl, "map_width"));
    try std.testing.expectEqual(@as(usize, 10), @offsetOf(IControl, "map_height"));
    try std.testing.expectEqual(@as(usize, 12), @offsetOf(IControl, "size"));
    try std.testing.expectEqual(@as(usize, 16), @offsetOf(IControl, "icons"));
    try std.testing.expectEqual(@as(usize, 20), @offsetOf(IControl, "palettes"));
    try std.testing.expectEqual(@as(usize, 24), @offsetOf(IControl, "remaps"));
    try std.testing.expectEqual(@as(usize, 28), @offsetOf(IControl, "trans_flag"));
    try std.testing.expectEqual(@as(usize, 32), @offsetOf(IControl, "color_map"));
    try std.testing.expectEqual(@as(usize, 36), @offsetOf(IControl, "map"));
    try std.testing.expectEqual(@as(usize, 40), @sizeOf(IControl));
}

test "IconSetRegistration layout matches ICONCACH.H on the active C target" {
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(IconSetRegistration, "icon_set_ptr"));
    try std.testing.expectEqual(@sizeOf(?*const IControl), @offsetOf(IconSetRegistration, "icon_list_offset"));
    try std.testing.expectEqual(
        std.mem.alignForward(usize, @offsetOf(IconSetRegistration, "icon_list_offset") + @sizeOf(c_int), @alignOf(IconSetRegistration)),
        @sizeOf(IconSetRegistration),
    );
}

test "Is_Icon_Cached uses the logical icon map before lookup" {
    resetIconCacheTestState();
    var icon_set = makeMappedIconSet(4, &.{ 3, 1, 0, 2 });
    test_state.icon_set_list[0] = .{ .icon_set_ptr = &icon_set.control, .icon_list_offset = 0 };
    test_state.icon_cache_lookup[3] = 77;

    try std.testing.expectEqual(@as(c_int, 77), Is_Icon_Cached(&icon_set.control, 0));
}

test "Is_Icon_Cached preserves high icon bits when applying the byte map" {
    resetIconCacheTestState();
    var icon_set = makeIconSet(0x200);
    icon_set.map[0x101] = 3;
    icon_set.control.map = @intCast(@intFromPtr(&icon_set.map) - @intFromPtr(&icon_set.control));
    test_state.icon_set_list[0] = .{ .icon_set_ptr = &icon_set.control, .icon_list_offset = 0 };
    test_state.icon_cache_lookup[0x103] = 88;

    try std.testing.expectEqual(@as(c_int, 88), Is_Icon_Cached(&icon_set.control, 0x101));
}

test "Is_Icon_Cached caches a registered miss into a free slot" {
    resetIconCacheTestState();
    var icon_set = makeIconSet(5);
    test_state.icon_set_list[0] = .{ .icon_set_ptr = &icon_set.control, .icon_list_offset = 4 };
    test_state.next_free_slot = 123;
    test_state.cache_new_result = 1;

    try std.testing.expectEqual(@as(c_int, 123), Is_Icon_Cached(&icon_set.control, 1));
    try std.testing.expectEqual(@as(c_int, 123), test_state.cache_new_icon_index);
    try std.testing.expectEqual(@intFromPtr(&icon_set.icons[icon_width * icon_height]), @intFromPtr(test_state.cache_new_icon_ptr.?));
    try std.testing.expectEqual(@as(c_short, 123), test_state.icon_cache_lookup[3]);
}

test "Is_Icon_Cached uses the icon set dimensions for cache miss pointers" {
    resetIconCacheTestState();
    var icon_set = makeSizedIconSet(16, 16, 5);
    test_state.icon_set_list[0] = .{ .icon_set_ptr = &icon_set.control, .icon_list_offset = 0 };
    test_state.next_free_slot = 55;
    test_state.cache_new_result = 1;

    try std.testing.expectEqual(@as(c_int, 55), Is_Icon_Cached(&icon_set.control, 2));
    try std.testing.expectEqual(@intFromPtr(&icon_set.icons[2 * 16 * 16]), @intFromPtr(test_state.cache_new_icon_ptr.?));
}

test "Is_Icon_Cached refreshes stamp state when the icon set changes" {
    resetIconCacheTestState();
    var first_set = makeSizedIconSet(16, 16, 5);
    var second_set = makeSizedIconSet(8, 8, 5);
    test_state.icon_set_list[0] = .{ .icon_set_ptr = &first_set.control, .icon_list_offset = 0 };
    test_state.icon_set_list[1] = .{ .icon_set_ptr = &second_set.control, .icon_list_offset = 10 };
    test_state.next_free_slot = 11;
    test_state.cache_new_result = 1;

    try std.testing.expectEqual(@as(c_int, 11), Is_Icon_Cached(&first_set.control, 2));
    try std.testing.expectEqual(@intFromPtr(&first_set.icons[2 * 16 * 16]), @intFromPtr(test_state.cache_new_icon_ptr.?));
    try std.testing.expectEqual(@intFromPtr(&first_set.control), @intFromPtr(stamp_info.last_icon_set.?));

    test_state.next_free_slot = 12;
    try std.testing.expectEqual(@as(c_int, 12), Is_Icon_Cached(&second_set.control, 2));
    try std.testing.expectEqual(@intFromPtr(&second_set.icons[2 * 8 * 8]), @intFromPtr(test_state.cache_new_icon_ptr.?));
    try std.testing.expectEqual(@intFromPtr(&second_set.control), @intFromPtr(stamp_info.last_icon_set.?));
}

test "Is_Icon_Cached rejects unregistered or out of range icons" {
    resetIconCacheTestState();
    var icon_set = makeIconSet(2);

    try std.testing.expectEqual(@as(c_int, -1), Is_Icon_Cached(null, 0));
    try std.testing.expectEqual(@as(c_int, -1), Is_Icon_Cached(&icon_set.control, 0));

    test_state.icon_set_list[0] = .{ .icon_set_ptr = &icon_set.control, .icon_list_offset = 0 };
    try std.testing.expectEqual(@as(c_int, -1), Is_Icon_Cached(&icon_set.control, -1));
    try std.testing.expectEqual(@as(c_int, -1), Is_Icon_Cached(&icon_set.control, 2));
}

fn resetIconCacheTestState() void {
    test_state.icon_set_list = [_]IconSetRegistration{.{ .icon_set_ptr = null, .icon_list_offset = 0 }} ** max_icon_sets;
    test_state.icon_cache_lookup = [_]c_short{-1} ** max_lookup_entries;
    test_state.next_free_slot = -1;
    test_state.cache_new_result = 0;
    test_state.cache_new_icon_index = -1;
    test_state.cache_new_icon_ptr = null;
    stamp_info = .{};
}

const TestIconSet = struct {
    control: IControl,
    map: [512]u8 = [_]u8{0} ** 512,
    icons: [8 * icon_width * icon_height]u8 = [_]u8{0} ** (8 * icon_width * icon_height),
};

fn makeIconSet(count: u16) TestIconSet {
    return makeSizedIconSet(icon_width, icon_height, count);
}

fn makeSizedIconSet(width: u16, height: u16, count: u16) TestIconSet {
    var icon_set = TestIconSet{
        .control = .{
            .width = width,
            .height = height,
            .count = count,
            .allocated = 0,
            .map_width = 0,
            .map_height = 0,
            .size = @sizeOf(TestIconSet),
            .icons = 0,
            .palettes = 0,
            .remaps = 0,
            .trans_flag = 0,
            .color_map = 0,
            .map = 0,
        },
    };
    icon_set.control.icons = @intCast(@intFromPtr(&icon_set.icons) - @intFromPtr(&icon_set.control));
    return icon_set;
}

fn makeMappedIconSet(count: u16, map_values: []const u8) TestIconSet {
    var icon_set = makeIconSet(count);
    @memcpy(icon_set.map[0..map_values.len], map_values);
    icon_set.control.map = @intCast(@intFromPtr(&icon_set.map) - @intFromPtr(&icon_set.control));
    return icon_set;
}
