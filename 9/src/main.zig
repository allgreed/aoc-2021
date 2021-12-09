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

    var heatmap = std.ArrayList(std.ArrayList(u8)).init(allocator);

    // TODO: often I find myself that I want to do a while over input
    // but do something on the first line
    const first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    const digits_per_line = first_line.?.len;
    try file.seekTo(0);

    {
        var row = std.ArrayList(u8).init(allocator);
        for (range(digits_per_line + 2)) |_, i| {
            try row.append(9);
        }
        try heatmap.append(row);
    }

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var row = std.ArrayList(u8).init(allocator);

        try row.append(9);
        for (line) |_, i| {
            const s = line[i .. i + 1];
            try row.append(try std.fmt.parseInt(u8, s, 10));
        }
        try row.append(9);

        try heatmap.append(row);
    }

    {
        var row = std.ArrayList(u8).init(allocator);
        for (range(digits_per_line + 2)) |_, i| {
            try row.append(9);
        }
        try heatmap.append(row);
    }

    var lowpoints = std.ArrayList(Point).init(allocator);
    for (range(heatmap.items.len - 2)) |_, _i| {
        const i = _i + 1;
        j: for (range(digits_per_line)) |_, _j| {
            const j = _j + 1;

            const cur = heatmap.items[i].items[j];
            for (range(4)) |_, k| {
                const cmp = switch (k) {
                    0 => heatmap.items[i + 1].items[j],
                    1 => heatmap.items[i - 1].items[j],
                    2 => heatmap.items[i].items[j + 1],
                    3 => heatmap.items[i].items[j - 1],
                    else => unreachable,
                };

                if (cmp <= cur)
                    continue :j;
            }

            try lowpoints.append(Point{ .x = i, .y = j });
        }
    }

    var basin_sizes = std.ArrayList(u64).init(allocator);
    var visited = try alloc2d(bool, heatmap.items.len, digits_per_line + 2, allocator);

    for (visited) |_, i| {
        for (visited[0]) |_, j| {
            visited[i][j] = false;
        }
    }

    var togo = std.ArrayList(Point).init(allocator);
    for (lowpoints.items) |lowpoint| {
        var size: u64 = 0;

        try togo.append(lowpoint);

        while (togo.popOrNull()) |p| {
            if (visited[p.x][p.y])
                continue;

            visited[p.x][p.y] = true;

            if (heatmap.items[p.x].items[p.y] == 9)
                continue;

            size += 1;

            try togo.append(p.move(1, 0));
            try togo.append(p.move(-1, 0));
            try togo.append(p.move(0, 1));
            try togo.append(p.move(0, -1));
        }

        try basin_sizes.append(size);
    }

    std.sort.sort(u64, basin_sizes.items, {}, comptime std.sort.desc(u64));

    std.log.info("{d}", .{basin_sizes.items[0] * basin_sizes.items[1] * basin_sizes.items[2]});
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

inline fn alloc2d(comptime t: type, m: usize, n: usize, allocator: *std.mem.Allocator) ![][]t {
    const array = try allocator.alloc([]t, m);
    for (array) |_, index| {
        array[index] = try allocator.alloc(t, n);
    }
    return array;
}
