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

pub fn genericPoint(comptime T: type) type {
    return struct {
        const Self = @This();

        x: T,
        y: T,

        pub fn eql(self: Self, other: Self) bool {
            return self.x == other.x and self.y == other.y;
        }

        pub fn move(self: Self, x: T, y: T) Self {
            return Self{ .x = self.x + x, .y = self.y + y };
        }
    };
}

pub fn genericPoint3(comptime T: type) type {
    return struct {
        const Self = @This();

        x: T,
        y: T,
        z: T,

        pub fn eql(self: Self, other: Self) bool {
            return std.meta.eql(self, other);
        }

        pub fn move(self: Self, x: T, y: T) Self {
            return Self{ .x = self.x + x, .y = self.y + y, .z = self.z + z };
        }
    };
}
