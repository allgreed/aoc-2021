const std = @import("std");

pub fn alloc2d(comptime t: type, m: usize, n: usize, allocator: *std.mem.Allocator) ![][]t {
    const array = try allocator.alloc([]t, m);
    for (array) |_, index| {
        array[index] = try allocator.alloc(t, n);
    }
    return array;
}

pub fn range(count: usize) []const u0 {
    return @as([*]u0, undefined)[0..count];
}

const Point = struct {
    x: usize,
    y: usize,

    fn eq(self: Point, other: Point) bool {
        return self.x == other.x and self.y == other.y;
    }
};
