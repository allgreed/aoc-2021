const std = @import("std");
const expect = std.testing.expect;
const max3 = std.math.max3;
const max = std.math.max;
const min = std.math.min;

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

    var buf: [1024]u8 = undefined;
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines = std.ArrayList(Line).init(allocator);
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var dash_idx: usize = 0;
        while (line[dash_idx] != '-')
            dash_idx += 1;

        const raw_start = line[0 .. dash_idx - 1];
        const raw_end = line[dash_idx + 1 + 2 ..];

        const start = try parse_point(raw_start);
        const end = try parse_point(raw_end);
        try lines.append(Line{ .start = start, .end = end });
    }

    var x_max: u32 = 0;
    var y_max: u32 = 0;
    for (lines.items) |line| {
        x_max = max3(x_max, line.start.x, line.end.x) + 1;
        y_max = max3(y_max, line.start.y, line.end.y) + 1;
    }

    var map = try alloc2d(u32, x_max, y_max, allocator);
    defer free2d(u32, map, allocator);

    for (map) |_, i| {
        for (map[i]) |_, j| {
            map[i][j] = 0;
        }
    }

    for (lines.items) |line| {
        if (line.start.x == line.end.x) {
            const y_begin = min(line.start.y, line.end.y);
            const y_end = max(line.start.y, line.end.y);
            {
                var i: usize = y_begin;
                while (i <= y_end) {
                    map[line.start.x][i] += 1;
                    i += 1;
                }
            }
        }

        if (line.start.y == line.end.y) {
            const x_begin = min(line.start.x, line.end.x);
            const x_end = max(line.start.x, line.end.x);
            {
                var i: usize = x_begin;
                while (i <= x_end) {
                    map[i][line.start.y] += 1;
                    i += 1;
                }
            }
        }
    }

    var intersection: u32 = 0;
    for (map) |r| {
        for (r) |v| {
            if (v > 1)
                intersection += 1;
        }
    }

    //for (map) |_, i| {
    //for (map[i]) |_, j| {
    //if (map[i][j] > 0)
    //std.debug.print("{d}", .{map[i][j]})
    //else
    //std.debug.print("{c}", .{'.'});
    //}
    //std.debug.print("\n", .{});
    //}
    std.log.info("{d}", .{intersection});
}

fn parse_point(raw: []u8) !Point {
    var comma_idx: usize = 0;
    while (raw[comma_idx] != ',')
        comma_idx += 1;

    const raw_x = raw[0..comma_idx];
    const raw_y = raw[comma_idx + 1 ..];

    const x = try std.fmt.parseInt(u32, raw_x, 10);
    const y = try std.fmt.parseInt(u32, raw_y, 10);

    return Point{ .x = x, .y = y };
}

const Point = struct {
    x: u32,
    y: u32,
};

const Line = struct {
    start: Point,
    end: Point,
};

// https://stackoverflow.com/questions/66630797/how-to-create-2d-arrays-of-containers-in-zig
inline fn alloc2d(comptime t: type, m: u32, n: u32, allocator: *std.mem.Allocator) ![][]t {
    const array = try allocator.alloc([]t, m);
    for (array) |_, index| {
        array[index] = try allocator.alloc(t, n);
    }
    return array;
}

inline fn free2d(comptime t: type, array: [][]t, allocator: *std.mem.Allocator) void {
    for (array) |_, index| {
        allocator.free(array[index]);
    }
    allocator.free(array);
}
