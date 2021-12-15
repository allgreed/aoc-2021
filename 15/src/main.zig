const std = @import("std");
const print = std.log.info;

const inf = std.math.maxInt(u32); // fairly close

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

    const first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    const mat_x_size = first_line.?.len;
    try file.seekTo(0);

    var g = Graph.init(mat_x_size, allocator);

    {
        var buffer = try allocator.alloc(u8, mat_x_size);
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            for (line) |_, i| {
                buffer[i] = try std.fmt.parseInt(u8, line[i .. i + 1], 10);
            }
            try g.add_row(buffer);
        }
    }

    const mat_y_size = g.points.items.len;
    const virt_x_size = 5 * mat_x_size;
    const virt_y_size = 5 * mat_y_size;

    g.width = virt_x_size;
    g.length = virt_y_size;

    var distance = try alloc2d(u32, virt_x_size, virt_y_size, allocator);
    var visited = std.AutoArrayHashMap(Point, bool).init(allocator);

    for (range(virt_y_size)) |_, y| {
        for (range(virt_x_size)) |_, x| {
            distance[y][x] = inf;
        }
    }
    distance[0][0] = 0;

    var q = std.PriorityQueue(Ble).init(allocator, Ble.compare);
    try q.add(.{ .p = .{
        .x = 0,
        .y = 0,
    }, .d = 0 });

    while (true) {
        const cur = q.remove().p;

        if (cur.x == virt_x_size - 1 and cur.y == virt_y_size - 1)
            break;

        // graphs is y,x
        try visited.put(cur, true);

        for (try g.neighbours(cur)) |p| {
            if (!visited.contains(p)) {
                var edge: u32 = g.points.items[p.y % mat_y_size][p.x % mat_x_size];

                if (p.y >= mat_y_size or p.x >= mat_x_size) {
                    edge += @intCast(u32, p.y / mat_y_size);
                    edge += @intCast(u32, p.x / mat_x_size);
                    if (edge >= 10) edge -= 9;
                }

                const alt = distance[cur.x][cur.y] + edge;
                if (alt < distance[p.x][p.y]) {
                    distance[p.x][p.y] = alt;
                    try q.add(.{ .p = p, .d = distance[p.x][p.y] });
                }
            }
        }
    }

    const p = .{ .x = mat_x_size * 5 - 2, .y = mat_y_size * 5 - 1 };
    print("{d}", .{distance[virt_x_size - 1][virt_y_size - 1]});
}

fn range(count: usize) []const u0 {
    return @as([*]u0, undefined)[0..count];
}

const Ble = struct {
    p: Point,
    d: u32,

    pub fn compare(this: Ble, other: Ble) std.math.Order {
        if (this.d == other.d)
            return std.math.Order.eq;

        return if (this.d > other.d) std.math.Order.gt else std.math.Order.lt;
    }
};

const Graph = struct {
    points: std.ArrayList([]u8),
    width: usize,
    allocator: *std.mem.Allocator,
    length: usize = undefined,

    fn neighbours(self: Graph, p: Point) ![]Point {
        var arr = std.ArrayList(Point).init(self.allocator);
        if (p.x > 0) {
            try arr.append(.{ .y = p.y, .x = p.x - 1 });
        }
        if (p.y > 0) {
            try arr.append(.{ .y = p.y - 1, .x = p.x });
        }
        if (p.x < self.width - 1) {
            try arr.append(.{ .y = p.y, .x = p.x + 1 });
        }
        if (p.y < self.length - 1) {
            try arr.append(.{ .y = p.y + 1, .x = p.x });
        }
        return arr.items;
    }

    fn add_row(self: *Graph, line: []const u8) !void {
        var row = try self.allocator.alloc(u8, self.width);
        std.mem.copy(u8, row, line);
        try self.points.append(row);
    }

    pub fn init(m: usize, allocator: *std.mem.Allocator) Graph {
        var points = std.ArrayList([]u8).init(allocator);
        return Graph{ .points = points, .width = m, .allocator = allocator };
    }
};

const Point = struct {
    x: usize,
    y: usize,

    fn eq(self: Point, other: Point) bool {
        return self.x == other.x and self.y == other.y;
    }
};

inline fn alloc2d(comptime t: type, m: usize, n: usize, allocator: *std.mem.Allocator) ![][]t {
    const array = try allocator.alloc([]t, m);
    for (array) |_, index| {
        array[index] = try allocator.alloc(t, n);
    }
    return array;
}
