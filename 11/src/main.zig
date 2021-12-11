const std = @import("std");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;
    var arg_it = std.process.args();
    _ = arg_it.skip();

    const filename = try (arg_it.next(allocator) orelse {
        std.debug.warn("Missing input filename\n", .{});
        return error.InvalidArgs;
    });

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf: [1024 * 4]u8 = undefined;
    var in_stream = file.reader();

    var octopi = try alloc2d(u8, 10 + 2, 10 + 2, allocator);

    {
        var i: usize = 0;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            for (line) |_, j| {
                octopi[i + 1][j + 1] = try std.fmt.parseInt(u8, line[j .. j + 1], 10);
            }

            i += 1;
        }
    }

    var s: u64 = 0;
    while (true) {
        var flashes = std.ArrayList(Point).init(allocator);
        var flashed = std.ArrayList(Point).init(allocator);

        for (range(10)) |_, _i| {
            const i = _i + 1;
            for (range(10)) |_, _j| {
                const j = _j + 1;

                octopi[i][j] += 1;
                if (octopi[i][j] == 10)
                    try flashes.append(Point{ .x = i, .y = j });
            }
        }

        while (flashes.popOrNull()) |p| {
            const _p = p.move(-1, -1);
            for (range(3)) |_, i| {
                for (range(3)) |_, j| {
                    octopi[_p.x + i][_p.y + j] += 1;
                    if (octopi[_p.x + i][_p.y + j] == 10)
                        try flashes.append(Point{ .x = _p.x + i, .y = _p.y + j });
                }
            }

            try flashed.append(p);
        }

        if (flashed.items.len == 100)
            break;

        while (flashed.popOrNull()) |p| {
            octopi[p.x][p.y] = 0;
        }

        for (range(12)) |_, i| {
            octopi[0][i] = 0;
            octopi[11][i] = 0;
            octopi[i][0] = 0;
            octopi[i][11] = 0;
        }

        s += 1;
    }

    //for (range(10)) |_, _i| {
    //const i = _i + 1;
    //for (range(10)) |_, _j| {
    //const j = _j + 1;

    //std.debug.print("{d}", .{octopi[i][j]});
    //}
    //std.debug.print("\n", .{});
    //}
    //
    std.log.info("{d}", .{s + 1});
}

inline fn alloc2d(comptime t: type, m: usize, n: usize, allocator: *std.mem.Allocator) ![][]t {
    const array = try allocator.alloc([]t, m);
    for (array) |_, index| {
        array[index] = try allocator.alloc(t, n);
    }
    return array;
}

fn range(count: usize) []const u0 {
    return @as([*]u0, undefined)[0..count];
}

const Point = struct {
    x: usize,
    y: usize,

    fn move(self: Point, x: i32, y: i32) Point {
        return Point{ .x = @intCast(usize, @intCast(i64, self.x) + x), .y = @intCast(usize, @intCast(i64, self.y) + y) };
    }
};
